import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:echo/core/constants.dart';
import 'package:echo/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  group('BackupService', () {
    test('export then restore reproduces memories and images', () async {
      final sourceImages = FakeImageStore()
        ..files['img_a.jpg'] = Uint8List.fromList(<int>[9, 8, 7, 6]);
      final source = InMemoryMemoryRepository(memories: [
        buildMemory(
          id: '1',
          title: 'مع صورة',
          images: <String>['img_a.jpg'],
          tags: <String>['t'],
          importance: 4,
        ),
        buildMemory(id: '2', title: 'بدون صورة', categoryId: 'goals'),
      ]);
      final json = await BackupService(
        repository: source,
        imageStore: sourceImages,
      ).buildBackupJson();

      final targetImages = FakeImageStore();
      final target = InMemoryMemoryRepository(
        memories: [buildMemory(id: 'old', title: 'قديمة')],
      );
      final result = await BackupService(
        repository: target,
        imageStore: targetImages,
      ).restore(json);

      expect(result.memories, 2);
      final restored = await target.getAllMemories();
      expect(restored.map((m) => m.id).toSet(), <String>{'1', '2'});
      final withImage = restored.firstWhere((m) => m.id == '1');
      expect(withImage.title, 'مع صورة');
      expect(withImage.tags, <String>['t']);
      expect(withImage.importance, 4);
      expect(targetImages.files['img_a.jpg'], <int>[9, 8, 7, 6]);
    });

    test('exportToFile writes a valid JSON file', () async {
      final repo = InMemoryMemoryRepository(
        memories: [buildMemory(id: '1', title: 'ملف')],
      );
      final dir = await Directory.systemTemp.createTemp('echo_backup_test');
      try {
        final file = await BackupService(
          repository: repo,
          imageStore: FakeImageStore(),
        ).exportToFile(dir, now: DateTime(2025, 2, 3, 4, 5));
        expect(file.path.endsWith('echo_backup_20250203_0405.json'), isTrue);
        final data = BackupService.parse(await file.readAsString());
        expect(data.memories.single.title, 'ملف');
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('rejects text that is not JSON', () {
      expect(
        () => BackupService.parse('not json'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects JSON that is not an ECHO backup', () {
      expect(
        () => BackupService.parse('{"hello": 1}'),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => BackupService.parse('[1, 2]'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects unsupported versions', () {
      final json = jsonEncode(<String, Object?>{
        'format': BackupService.formatId,
        'version': 999,
        'categories': <Object?>[],
        'memories': <Object?>[],
      });
      expect(
        () => BackupService.parse(json),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects memories missing required fields', () {
      final json = jsonEncode(<String, Object?>{
        'format': BackupService.formatId,
        'version': 1,
        'categories': <Object?>[],
        'memories': <Object?>[
          <String, Object?>{'id': 'x'},
        ],
      });
      expect(
        () => BackupService.parse(json),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('failed validation never touches existing data', () async {
      final repo = InMemoryMemoryRepository(
        memories: [buildMemory(id: 'keep', title: 'يجب أن تبقى')],
      );
      final service = BackupService(
        repository: repo,
        imageStore: FakeImageStore(),
      );
      await expectLater(
        service.restore('{"format":"echo-backup","version":1,"categories":[],"memories":[{"id":"x"}]}'),
        throwsA(isA<BackupFormatException>()),
      );
      final all = await repo.getAllMemories();
      expect(all.single.id, 'keep');
    });

    test('unknown categories fall back and unsafe image names are dropped', () {
      final json = jsonEncode(<String, Object?>{
        'format': BackupService.formatId,
        'version': 1,
        'categories': <Object?>[],
        'memories': <Object?>[
          <String, Object?>{
            'id': 'm',
            'title': 'اختبار',
            'occurredAt': 1700000000000,
            'categoryId': 'does-not-exist',
            'importance': 99,
            'images': <String>['../../evil.jpg', 'ok.jpg'],
          },
        ],
        'images': <String, Object?>{
          '../../evil.jpg': base64Encode(<int>[1]),
          'ok.jpg': base64Encode(<int>[2]),
        },
      });
      final data = BackupService.parse(json);
      final memory = data.memories.single;
      expect(memory.categoryId, kFallbackCategoryId);
      expect(memory.importance, 5);
      expect(memory.images, <String>['ok.jpg']);
      expect(data.images.keys, <String>['ok.jpg']);
      expect(data.categories.any((c) => c.id == kFallbackCategoryId), isTrue);
    });

    test('rejects corrupt base64 image data', () {
      final json = jsonEncode(<String, Object?>{
        'format': BackupService.formatId,
        'version': 1,
        'categories': <Object?>[],
        'memories': <Object?>[],
        'images': <String, Object?>{'a.jpg': '***not-base64***'},
      });
      expect(
        () => BackupService.parse(json),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}
