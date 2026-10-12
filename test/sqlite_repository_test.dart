import 'dart:io';

import 'package:echo/core/constants.dart';
import 'package:echo/data/db/app_database.dart';
import 'package:echo/data/models/memory.dart';
import 'package:echo/data/models/memory_category.dart';
import 'package:echo/data/repositories/sqlite_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fakes.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  group('SqliteMemoryRepository (in-memory database)', () {
    late SqliteMemoryRepository repository;

    setUp(() async {
      final db = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      repository = SqliteMemoryRepository(db);
    });

    tearDown(() => repository.close());

    test('fresh database is empty but has the default categories', () async {
      expect(await repository.getAllMemories(), isEmpty);
      final categories = await repository.getCategories();
      expect(categories.length, kDefaultCategories.length);
      expect(categories.first.id, kFallbackCategoryId);
    });

    test('insert, update, query and delete a memory', () async {
      await repository.upsertMemory(
        buildMemory(id: 'm1', title: 'الأولى', tags: <String>['x']),
      );
      var all = await repository.getAllMemories();
      expect(all.single.title, 'الأولى');
      expect(all.single.tags, <String>['x']);

      await repository.upsertMemory(
        buildMemory(id: 'm1', title: 'بعد التعديل'),
      );
      all = await repository.getAllMemories();
      expect(all.length, 1);
      expect(all.single.title, 'بعد التعديل');

      await repository.deleteMemory('m1');
      expect(await repository.getAllMemories(), isEmpty);
    });

    test('memories are returned newest first', () async {
      await repository.upsertMemory(
        buildMemory(id: 'old', occurredAt: DateTime(2020, 1, 1)),
      );
      await repository.upsertMemory(
        buildMemory(id: 'new', occurredAt: DateTime(2025, 1, 1)),
      );
      final all = await repository.getAllMemories();
      expect(all.map((m) => m.id), <String>['new', 'old']);
    });

    test('deleting a category moves its memories to the fallback', () async {
      await repository.upsertCategory(const MemoryCategory(
        id: 'custom',
        name: 'مخصص',
        colorValue: 0xFF123456,
        iconKey: 'star',
        sortOrder: 99,
      ));
      await repository.upsertMemory(
        buildMemory(id: 'm1', categoryId: 'custom'),
      );
      await repository.deleteCategory('custom');

      final categories = await repository.getCategories();
      expect(categories.any((c) => c.id == 'custom'), isFalse);
      final memory = (await repository.getAllMemories()).single;
      expect(memory.categoryId, kFallbackCategoryId);
    });

    test('the fallback category cannot be deleted', () async {
      expect(
        () => repository.deleteCategory(kFallbackCategoryId),
        throwsArgumentError,
      );
    });

    test('settings are stored and overwritten', () async {
      expect(await repository.getSetting('k'), isNull);
      await repository.setSetting('k', 'a');
      await repository.setSetting('k', 'b');
      expect(await repository.getSetting('k'), 'b');
    });

    test('replaceAll swaps all data atomically', () async {
      await repository.upsertMemory(buildMemory(id: 'old'));
      await repository.replaceAll(
        categories: kDefaultCategories,
        memories: <Memory>[buildMemory(id: 'n1'), buildMemory(id: 'n2')],
      );
      final all = await repository.getAllMemories();
      expect(all.map((m) => m.id).toSet(), <String>{'n1', 'n2'});
    });

    test('clearMemories removes memories but keeps categories', () async {
      await repository.upsertMemory(buildMemory(id: 'm'));
      await repository.clearMemories();
      expect(await repository.getAllMemories(), isEmpty);
      expect(await repository.getCategories(), isNotEmpty);
    });
  });

  test('data survives closing and reopening the database file', () async {
    final dir = await Directory.systemTemp.createTemp('echo_db_test');
    final path = '${dir.path}/echo_test.db';
    try {
      var db = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
      var repository = SqliteMemoryRepository(db);
      await repository.upsertMemory(
        buildMemory(id: 'persist', title: 'تبقى بعد الإغلاق'),
      );
      await repository.close();

      db = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
      repository = SqliteMemoryRepository(db);
      final all = await repository.getAllMemories();
      expect(all.single.title, 'تبقى بعد الإغلاق');
      await repository.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
