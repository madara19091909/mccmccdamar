import 'package:echo/core/constants.dart';
import 'package:echo/data/models/memory.dart';
import 'package:echo/data/models/memory_category.dart';
import 'package:echo/data/repositories/memory_repository.dart';
import 'package:sqflite/sqflite.dart';

class SqliteMemoryRepository implements MemoryRepository {
  SqliteMemoryRepository(this._db);

  final Database _db;

  @override
  Future<List<Memory>> getAllMemories() async {
    final rows = await _db.query('memories', orderBy: 'occurred_at DESC');
    return rows.map(Memory.fromMap).toList();
  }

  @override
  Future<void> upsertMemory(Memory memory) async {
    await _db.insert(
      'memories',
      memory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteMemory(String id) async {
    await _db.delete('memories', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  @override
  Future<void> clearMemories() async {
    await _db.delete('memories');
  }

  @override
  Future<List<MemoryCategory>> getCategories() async {
    final rows =
        await _db.query('categories', orderBy: 'sort_order ASC, name ASC');
    return rows.map(MemoryCategory.fromMap).toList();
  }

  @override
  Future<void> upsertCategory(MemoryCategory category) async {
    await _db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    if (id == kFallbackCategoryId) {
      throw ArgumentError('The default category cannot be deleted.');
    }
    await _db.transaction((txn) async {
      await txn.update(
        'memories',
        <String, Object?>{'category_id': kFallbackCategoryId},
        where: 'category_id = ?',
        whereArgs: <Object?>[id],
      );
      await txn.delete('categories', where: 'id = ?', whereArgs: <Object?>[id]);
    });
  }

  @override
  Future<String?> getSetting(String key) async {
    final rows = await _db.query(
      'settings',
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    await _db.insert(
      'settings',
      <String, Object?>{'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> replaceAll({
    required List<MemoryCategory> categories,
    required List<Memory> memories,
  }) async {
    if (!categories.any((c) => c.id == kFallbackCategoryId)) {
      throw ArgumentError('The default category is required.');
    }
    await _db.transaction((txn) async {
      await txn.delete('memories');
      await txn.delete('categories');
      final batch = txn.batch();
      for (final category in categories) {
        batch.insert('categories', category.toMap());
      }
      for (final memory in memories) {
        batch.insert('memories', memory.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> close() => _db.close();
}
