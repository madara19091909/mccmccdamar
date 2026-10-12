import 'package:echo/core/constants.dart';
import 'package:echo/data/image_store.dart';
import 'package:echo/data/models/memory.dart';
import 'package:echo/data/models/memory_category.dart';
import 'package:echo/data/repositories/memory_repository.dart';
import 'package:echo/logic/memory_query.dart';
import 'package:echo/logic/memory_stats.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;

class MemoryController extends ChangeNotifier {
  MemoryController({
    required MemoryRepository repository,
    required ImageStore imageStore,
  })  : _repository = repository,
        _imageStore = imageStore;

  final MemoryRepository _repository;
  final ImageStore _imageStore;

  List<Memory> _memories = const <Memory>[];
  List<MemoryCategory> _categories = const <MemoryCategory>[];
  bool _isLoading = true;
  String? _errorMessage;

  String searchText = '';
  String? categoryFilter;
  MemorySort sort = MemorySort.newest;
  DateTimeRange? dateRange;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Memory> get memories => _memories;
  List<MemoryCategory> get categories => _categories;

  List<Memory> get filteredMemories => applyMemoryQuery(
        _memories,
        search: searchText,
        categoryId: categoryFilter,
        sort: sort,
        range: dateRange,
      );

  MemoryStats get stats => MemoryStats.compute(_memories, DateTime.now());

  MemoryCategory? categoryById(String id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Memory? memoryById(String id) {
    for (final memory in _memories) {
      if (memory.id == id) return memory;
    }
    return null;
  }

  Future<void> load() async {
    try {
      _categories = await _repository.getCategories();
      _memories = await _repository.getAllMemories();
      _errorMessage = null;
    } catch (error) {
      debugPrint('ECHO: load failed (${error.runtimeType})');
      _errorMessage = 'تعذّر تحميل بياناتك المحلية. حاول مرة أخرى.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---- Filters -----------------------------------------------------------

  void setSearchText(String value) {
    searchText = value;
    notifyListeners();
  }

  void setCategoryFilter(String? id) {
    categoryFilter = id;
    notifyListeners();
  }

  void setSort(MemorySort value) {
    sort = value;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? value) {
    dateRange = value;
    notifyListeners();
  }

  void resetFilters() {
    searchText = '';
    categoryFilter = null;
    dateRange = null;
    notifyListeners();
  }

  // ---- Memories ----------------------------------------------------------

  /// Returns true on success. [removedImages] are deleted after a successful save.
  Future<bool> saveMemory(
    Memory memory, {
    List<String> removedImages = const <String>[],
  }) async {
    try {
      await _repository.upsertMemory(memory);
    } catch (error) {
      debugPrint('ECHO: save failed (${error.runtimeType})');
      return false;
    }
    _memories = <Memory>[
      ..._memories.where((m) => m.id != memory.id),
      memory,
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    notifyListeners();
    for (final name in removedImages) {
      await _imageStore.delete(name);
    }
    return true;
  }

  Future<bool> deleteMemory(String id) async {
    final memory = memoryById(id);
    try {
      await _repository.deleteMemory(id);
    } catch (error) {
      debugPrint('ECHO: delete failed (${error.runtimeType})');
      return false;
    }
    _memories = _memories.where((m) => m.id != id).toList();
    notifyListeners();
    if (memory != null) {
      for (final name in memory.images) {
        await _imageStore.delete(name);
      }
    }
    return true;
  }

  Future<bool> clearAllMemories() async {
    try {
      await _repository.clearMemories();
    } catch (error) {
      debugPrint('ECHO: clear failed (${error.runtimeType})');
      return false;
    }
    _memories = const <Memory>[];
    notifyListeners();
    await _imageStore.clear();
    return true;
  }

  // ---- Categories --------------------------------------------------------

  Future<bool> saveCategory(MemoryCategory category) async {
    try {
      await _repository.upsertCategory(category);
    } catch (error) {
      debugPrint('ECHO: category save failed (${error.runtimeType})');
      return false;
    }
    _categories = <MemoryCategory>[
      ..._categories.where((c) => c.id != category.id),
      category,
    ]..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
    notifyListeners();
    return true;
  }

  Future<bool> deleteCategory(String id) async {
    if (id == kFallbackCategoryId) return false;
    try {
      await _repository.deleteCategory(id);
    } catch (error) {
      debugPrint('ECHO: category delete failed (${error.runtimeType})');
      return false;
    }
    _categories = _categories.where((c) => c.id != id).toList();
    _memories = _memories
        .map((m) => m.categoryId == id
            ? m.copyWith(categoryId: kFallbackCategoryId)
            : m)
        .toList();
    if (categoryFilter == id) categoryFilter = null;
    notifyListeners();
    return true;
  }
}
