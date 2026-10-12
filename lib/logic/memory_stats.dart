import 'package:echo/data/models/memory.dart';

/// Statistics computed only from the user's real, local memories.
class MemoryStats {
  const MemoryStats({
    required this.total,
    required this.perCategory,
    required this.addedToday,
    required this.addedLast7Days,
    required this.addedLast30Days,
    required this.addedThisYear,
    required this.averageImportance,
    required this.lastActivity,
  });

  final int total;
  final Map<String, int> perCategory;
  final int addedToday;
  final int addedLast7Days;
  final int addedLast30Days;
  final int addedThisYear;
  final double averageImportance;
  final DateTime? lastActivity;

  int get categoriesInUse => perCategory.values.where((n) => n > 0).length;

  factory MemoryStats.compute(List<Memory> memories, DateTime now) {
    final startOfToday = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final perCategory = <String, int>{};
    var today = 0;
    var week = 0;
    var month = 0;
    var year = 0;
    var importanceSum = 0;
    DateTime? last;

    for (final memory in memories) {
      perCategory[memory.categoryId] =
          (perCategory[memory.categoryId] ?? 0) + 1;
      final created = memory.createdAt;
      if (!created.isBefore(startOfToday)) today++;
      if (created.isAfter(sevenDaysAgo)) week++;
      if (created.isAfter(thirtyDaysAgo)) month++;
      if (created.year == now.year) year++;
      importanceSum += memory.importance;
      if (last == null || memory.updatedAt.isAfter(last)) {
        last = memory.updatedAt;
      }
    }

    return MemoryStats(
      total: memories.length,
      perCategory: perCategory,
      addedToday: today,
      addedLast7Days: week,
      addedLast30Days: month,
      addedThisYear: year,
      averageImportance:
          memories.isEmpty ? 0 : importanceSum / memories.length,
      lastActivity: last,
    );
  }
}
