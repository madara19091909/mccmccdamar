import 'package:echo/data/models/memory.dart';
import 'package:echo/data/models/memory_category.dart';

/// Storage contract used by the app. The production implementation is SQLite.
abstract class MemoryRepository {
  Future<List<Memory>> getAllMemories();
  Future<void> upsertMemory(Memory memory);
  Future<void> deleteMemory(String id);
  Future<void> clearMemories();

  Future<List<MemoryCategory>> getCategories();
  Future<void> upsertCategory(MemoryCategory category);

  /// Deletes a category and moves its memories to the fallback category.
  Future<void> deleteCategory(String id);

  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);

  /// Atomically replaces every category and memory (used by restore).
  Future<void> replaceAll({
    required List<MemoryCategory> categories,
    required List<Memory> memories,
  });
}
