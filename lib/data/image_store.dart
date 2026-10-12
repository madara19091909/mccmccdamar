import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final RegExp _safeImageName =
    RegExp(r'^[A-Za-z0-9_\-]{1,80}\.(jpg|jpeg|png|webp|gif)$');

/// Only plain file names are allowed (no folders), which blocks path tricks
/// when names come from an imported backup file.
bool isSafeImageName(String name) => _safeImageName.hasMatch(name);

abstract class ImageStore {
  /// Copies a picked image into private storage and returns its stored name.
  Future<String> importFile(String sourcePath);
  File fileFor(String name);
  Future<Uint8List?> read(String name);
  Future<void> write(String name, Uint8List bytes);
  Future<void> delete(String name);
  Future<void> clear();
}

class FileImageStore implements ImageStore {
  FileImageStore(this.directory);

  final Directory directory;

  static final Random _random = Random();
  static const Set<String> _allowedExtensions = <String>{
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
  };

  static Future<FileImageStore> create() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'echo_images'));
    await dir.create(recursive: true);
    return FileImageStore(dir);
  }

  @override
  Future<String> importFile(String sourcePath) async {
    final extension = p.extension(sourcePath).toLowerCase();
    final safeExtension =
        _allowedExtensions.contains(extension) ? extension : '.jpg';
    final name =
        'img_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 20)}$safeExtension';
    await File(sourcePath).copy(p.join(directory.path, name));
    return name;
  }

  @override
  File fileFor(String name) {
    if (!isSafeImageName(name)) {
      return File(p.join(directory.path, '_invalid'));
    }
    return File(p.join(directory.path, name));
  }

  @override
  Future<Uint8List?> read(String name) async {
    final file = fileFor(name);
    if (await file.exists()) return file.readAsBytes();
    return null;
  }

  @override
  Future<void> write(String name, Uint8List bytes) async {
    if (!isSafeImageName(name)) {
      throw ArgumentError('Unsafe image name.');
    }
    await fileFor(name).writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> delete(String name) async {
    try {
      final file = fileFor(name);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Best effort: a missing or locked file must not break the UI flow.
    }
  }

  @override
  Future<void> clear() async {
    try {
      if (!await directory.exists()) return;
      await for (final entity in directory.list()) {
        if (entity is File) await entity.delete();
      }
    } on FileSystemException {
      // Best effort cleanup.
    }
  }
}
