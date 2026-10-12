import 'dart:io';
import 'dart:typed_data';

import 'package:echo/core/constants.dart';
import 'package:echo/data/image_store.dart';
import 'package:echo/data/models/memory.dart';
import 'package:echo/data/models/memory_category.dart';
import 'package:echo/data/repositories/memory_repository.dart';

/// In-memory test double that follows the same rules as the SQLite repository.
class InMemoryMemoryRepository implements MemoryRepository {
  InMemoryMemoryRepository({
    List<Memory> memories = const <Memory>[],
    Map<String, String> settings = const <String, String>{},
  })  : _memories = <Memory>[...memories],
        _categories = <MemoryCategory>[...kDefaultCategories],
        _settings = <String, String>{...settings};

  final List<Memory> _memories;
  List<MemoryCategory> _categories;
  final Map<String, String> _settings;

  @override
  Future<List<Memory>> getAllMemories() async {
    final copy = <Memory>[..._memories]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return copy;
  }

  @override
  Future<void> upsertMemory(Memory memory) async {
    _memories.removeWhere((m) => m.id == memory.id);
    _memories.add(memory);
  }

  @override
  Future<void> deleteMemory(String id) async {
    _memories.removeWhere((m) => m.id == id);
  }

  @override
  Future<void> clearMemories() async => _memories.clear();

  @override
  Future<List<MemoryCategory>> getCategories() async =>
      <MemoryCategory>[..._categories]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  Future<void> upsertCategory(MemoryCategory category) async {
    _categories = <MemoryCategory>[
      ..._categories.where((c) => c.id != category.id),
      category,
    ];
  }

  @override
  Future<void> deleteCategory(String id) async {
    if (id == kFallbackCategoryId) {
      throw ArgumentError('The default category cannot be deleted.');
    }
    for (var i = 0; i < _memories.length; i++) {
      if (_memories[i].categoryId == id) {
        _memories[i] = _memories[i].copyWith(categoryId: kFallbackCategoryId);
      }
    }
    _categories = _categories.where((c) => c.id != id).toList();
  }

  @override
  Future<String?> getSetting(String key) async => _settings[key];

  @override
  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
  }

  @override
  Future<void> replaceAll({
    required List<MemoryCategory> categories,
    required List<Memory> memories,
  }) async {
    _categories = <MemoryCategory>[...categories];
    _memories
      ..clear()
      ..addAll(memories);
  }
}

class FakeImageStore implements ImageStore {
  final Map<String, Uint8List> files = <String, Uint8List>{};

  @override
  Future<String> importFile(String sourcePath) async {
    final name = 'img_${files.length}.jpg';
    files[name] = Uint8List.fromList(<int>[1, 2, 3]);
    return name;
  }

  @override
  File fileFor(String name) => File('/nonexistent/echo_test/$name');

  @override
  Future<Uint8List?> read(String name) async => files[name];

  @override
  Future<void> write(String name, Uint8List bytes) async {
    files[name] = bytes;
  }

  @override
  Future<void> delete(String name) async {
    files.remove(name);
  }

  @override
  Future<void> clear() async => files.clear();
}

Memory buildMemory({
  required String id,
  String title = 'ذكرى',
  String body = '',
  DateTime? occurredAt,
  String categoryId = 'life',
  List<String> tags = const <String>[],
  int importance = 3,
  List<String> images = const <String>[],
  DateTime? createdAt,
}) {
  final date = occurredAt ?? DateTime(2025, 1, 1, 10);
  return Memory(
    id: id,
    title: title,
    body: body,
    occurredAt: date,
    createdAt: createdAt ?? date,
    updatedAt: createdAt ?? date,
    categoryId: categoryId,
    tags: tags,
    colorValue: 0xFF8B7CFF,
    importance: importance,
    images: images,
  );
}
