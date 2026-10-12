import 'package:echo/data/models/memory.dart';
import 'package:flutter/material.dart' show DateTimeRange;

enum MemorySort { newest, oldest, importance }

/// Pure function: search + category filter + date range + sorting.
List<Memory> applyMemoryQuery(
  List<Memory> source, {
  String search = '',
  String? categoryId,
  MemorySort sort = MemorySort.newest,
  DateTimeRange? range,
}) {
  final query = search.trim().toLowerCase();
  final results = source.where((memory) {
    if (categoryId != null && memory.categoryId != categoryId) return false;
    if (range != null) {
      final start =
          DateTime(range.start.year, range.start.month, range.start.day);
      final end = DateTime(range.end.year, range.end.month, range.end.day)
          .add(const Duration(days: 1));
      if (memory.occurredAt.isBefore(start) ||
          !memory.occurredAt.isBefore(end)) {
        return false;
      }
    }
    if (query.isEmpty) return true;
    return memory.title.toLowerCase().contains(query) ||
        memory.body.toLowerCase().contains(query) ||
        memory.tags.any((tag) => tag.toLowerCase().contains(query));
  }).toList();

  switch (sort) {
    case MemorySort.newest:
      results.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    case MemorySort.oldest:
      results.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    case MemorySort.importance:
      results.sort((a, b) {
        final byImportance = b.importance.compareTo(a.importance);
        return byImportance != 0
            ? byImportance
            : b.occurredAt.compareTo(a.occurredAt);
      });
  }
  return results;
}
