import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:echo/core/constants.dart';
import 'package:echo/core/icons.dart';
import 'package:echo/data/image_store.dart';
import 'package:echo/data/models/memory.dart';
import 'package:echo/data/models/memory_category.dart';
import 'package:echo/data/repositories/memory_repository.dart';
import 'package:path/path.dart' as p;

class BackupFormatException implements Exception {
  BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupData {
  const BackupData({
    required this.categories,
    required this.memories,
    required this.images,
  });

  final List<MemoryCategory> categories;
  final List<Memory> memories;
  final Map<String, Uint8List> images;
}

class RestoreResult {
  const RestoreResult({required this.memories, required this.categories});

  final int memories;
  final int categories;
}

/// Export/import of the whole local world as one JSON file (images embedded
/// as base64). Imported files are fully validated before anything is changed.
class BackupService {
  BackupService({required this.repository, required this.imageStore});

  final MemoryRepository repository;
  final ImageStore imageStore;

  static const String formatId = 'echo-backup';
  static const int formatVersion = 1;

  static const int _maxTimestamp = 8640000000000000;

  Future<String> buildBackupJson({DateTime? now}) async {
    final categories = await repository.getCategories();
    final memories = await repository.getAllMemories();
    final images = <String, String>{};
    for (final memory in memories) {
      for (final name in memory.images) {
        if (images.containsKey(name) || !isSafeImageName(name)) continue;
        final bytes = await imageStore.read(name);
        if (bytes != null) images[name] = base64Encode(bytes);
      }
    }
    return jsonEncode(<String, Object?>{
      'format': formatId,
      'version': formatVersion,
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'memories': memories.map((m) => m.toJson()).toList(),
      'images': images,
    });
  }

  Future<File> exportToFile(Directory directory, {DateTime? now}) async {
    final time = now ?? DateTime.now();
    final json = await buildBackupJson(now: time);
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${time.year}${two(time.month)}${two(time.day)}_${two(time.hour)}${two(time.minute)}';
    final file = File(p.join(directory.path, 'echo_backup_$stamp.json'));
    return file.writeAsString(json, flush: true);
  }

  /// Parses and validates a backup. Throws [BackupFormatException] with an
  /// Arabic, user-facing message when the file is not a valid ECHO backup.
  static BackupData parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw BackupFormatException('الملف ليس بصيغة JSON صالحة.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw BackupFormatException('بنية الملف غير معروفة.');
    }
    if (decoded['format'] != formatId) {
      throw BackupFormatException('هذا الملف ليس نسخة احتياطية من ECHO.');
    }
    final version = decoded['version'];
    if (version is! int || version < 1 || version > formatVersion) {
      throw BackupFormatException('إصدار النسخة الاحتياطية غير مدعوم.');
    }
    final rawCategories = decoded['categories'];
    final rawMemories = decoded['memories'];
    if (rawCategories is! List || rawMemories is! List) {
      throw BackupFormatException('الملف لا يحتوي على قوائم التصنيفات والذكريات.');
    }

    final categories = <MemoryCategory>[];
    final categoryIds = <String>{};
    for (var i = 0; i < rawCategories.length; i++) {
      final item = rawCategories[i];
      if (item is! Map<String, dynamic>) {
        throw BackupFormatException('التصنيف رقم ${i + 1} غير صالح.');
      }
      final id = item['id'];
      final name = item['name'];
      final color = item['color'];
      if (id is! String ||
          id.isEmpty ||
          name is! String ||
          name.trim().isEmpty ||
          color is! int) {
        throw BackupFormatException('التصنيف رقم ${i + 1} ينقصه حقول أساسية.');
      }
      if (!categoryIds.add(id)) continue;
      final icon = item['icon'];
      final order = item['sortOrder'];
      categories.add(MemoryCategory(
        id: id,
        name: name.trim(),
        colorValue: color & 0xFFFFFFFF,
        iconKey: icon is String && kIconChoices.containsKey(icon)
            ? icon
            : 'star',
        sortOrder: order is int ? order : i,
      ));
    }
    if (!categoryIds.contains(kFallbackCategoryId)) {
      categories.insert(
        0,
        kDefaultCategories.firstWhere((c) => c.id == kFallbackCategoryId),
      );
      categoryIds.add(kFallbackCategoryId);
    }

    final memories = <Memory>[];
    final memoryIds = <String>{};
    for (var i = 0; i < rawMemories.length; i++) {
      final item = rawMemories[i];
      if (item is! Map<String, dynamic>) {
        throw BackupFormatException('الذكرى رقم ${i + 1} غير صالحة.');
      }
      final id = item['id'];
      final title = item['title'];
      final occurred = item['occurredAt'];
      if (id is! String ||
          id.isEmpty ||
          title is! String ||
          title.trim().isEmpty ||
          occurred is! int) {
        throw BackupFormatException('الذكرى رقم ${i + 1} ينقصها حقول أساسية.');
      }
      if (!memoryIds.add(id)) continue;
      final createdRaw = item['createdAt'];
      final updatedRaw = item['updatedAt'];
      final created = createdRaw is int ? createdRaw : occurred;
      final updated = updatedRaw is int ? updatedRaw : created;
      for (final stamp in <int>[occurred, created, updated]) {
        if (stamp.abs() > _maxTimestamp) {
          throw BackupFormatException('الذكرى رقم ${i + 1} تحتوي تاريخًا غير صالح.');
        }
      }
      final categoryId = item['categoryId'];
      final color = item['color'];
      final icon = item['icon'];
      final importance = item['importance'];
      final body = item['body'];
      final tags = item['tags'];
      final images = item['images'];
      memories.add(Memory(
        id: id,
        title: title.trim(),
        body: body is String ? body : '',
        occurredAt: DateTime.fromMillisecondsSinceEpoch(occurred),
        createdAt: DateTime.fromMillisecondsSinceEpoch(created),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updated),
        categoryId: categoryId is String && categoryIds.contains(categoryId)
            ? categoryId
            : kFallbackCategoryId,
        tags: tags is List
            ? tags.whereType<String>().take(kMaxTagsPerMemory).toList()
            : const <String>[],
        colorValue: color is int ? color & 0xFFFFFFFF : kPaletteColors.first,
        iconKey:
            icon is String && kIconChoices.containsKey(icon) ? icon : 'star',
        importance: importance is int ? importance.clamp(1, 5).toInt() : 3,
        images: images is List
            ? images
                .whereType<String>()
                .where(isSafeImageName)
                .take(kMaxImagesPerMemory)
                .toList()
            : const <String>[],
      ));
    }

    final rawImages = decoded['images'];
    final imageBytes = <String, Uint8List>{};
    if (rawImages != null) {
      if (rawImages is! Map<String, dynamic>) {
        throw BackupFormatException('قسم الصور في الملف غير صالح.');
      }
      for (final entry in rawImages.entries) {
        if (!isSafeImageName(entry.key)) continue;
        final value = entry.value;
        if (value is! String) {
          throw BackupFormatException('بيانات إحدى الصور غير صالحة.');
        }
        try {
          imageBytes[entry.key] = base64Decode(value);
        } on FormatException {
          throw BackupFormatException('بيانات إحدى الصور تالفة داخل الملف.');
        }
      }
    }

    return BackupData(
      categories: categories,
      memories: memories,
      images: imageBytes,
    );
  }

  /// Replaces all current data with [data]. Images are written first so a
  /// database failure leaves the previous data untouched.
  Future<RestoreResult> restoreData(BackupData data) async {
    for (final entry in data.images.entries) {
      await imageStore.write(entry.key, entry.value);
    }
    await repository.replaceAll(
      categories: data.categories,
      memories: data.memories,
    );
    return RestoreResult(
      memories: data.memories.length,
      categories: data.categories.length,
    );
  }

  Future<RestoreResult> restore(String source) async {
  final data = parse(source);
  return restoreData(data);
  }