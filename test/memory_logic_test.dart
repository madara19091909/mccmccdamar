import 'package:echo/data/models/memory.dart';
import 'package:echo/logic/memory_query.dart';
import 'package:echo/logic/memory_stats.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  group('Memory model', () {
    test('map round trip keeps every field', () {
      final original = buildMemory(
        id: 'a',
        title: 'عنوان',
        body: 'نص',
        tags: <String>['سفر', 'عائلة'],
        importance: 5,
        images: <String>['img_1.jpg'],
      );
      final restored = Memory.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.title, 'عنوان');
      expect(restored.body, 'نص');
      expect(restored.tags, <String>['سفر', 'عائلة']);
      expect(restored.importance, 5);
      expect(restored.images, <String>['img_1.jpg']);
      expect(restored.occurredAt, original.occurredAt);
    });

    test('newId generates unique ids', () {
      final ids = List<String>.generate(200, (_) => Memory.newId());
      expect(ids.toSet().length, ids.length);
    });
  });

  group('applyMemoryQuery', () {
    final memories = <Memory>[
      buildMemory(
        id: '1',
        title: 'رحلة الجبل',
        body: 'يوم رائع',
        occurredAt: DateTime(2025, 3, 10),
        categoryId: 'life',
        importance: 2,
      ),
      buildMemory(
        id: '2',
        title: 'فكرة مشروع',
        occurredAt: DateTime(2025, 5, 1),
        categoryId: 'thoughts',
        tags: <String>['عمل'],
        importance: 5,
      ),
      buildMemory(
        id: '3',
        title: 'تخرّجت',
        occurredAt: DateTime(2024, 6, 20),
        categoryId: 'achievements',
        importance: 4,
      ),
    ];

    test('search matches title, body and tags', () {
      expect(applyMemoryQuery(memories, search: 'الجبل').map((m) => m.id), ['1']);
      expect(applyMemoryQuery(memories, search: 'رائع').map((m) => m.id), ['1']);
      expect(applyMemoryQuery(memories, search: 'عمل').map((m) => m.id), ['2']);
      expect(applyMemoryQuery(memories, search: 'غير موجود'), isEmpty);
    });

    test('filters by category', () {
      final result = applyMemoryQuery(memories, categoryId: 'achievements');
      expect(result.map((m) => m.id), ['3']);
    });

    test('filters by date range (inclusive of the end day)', () {
      final result = applyMemoryQuery(
        memories,
        range: DateTimeRange(
          start: DateTime(2025, 3, 1),
          end: DateTime(2025, 3, 10),
        ),
      );
      expect(result.map((m) => m.id), ['1']);
    });

    test('sorts newest, oldest and by importance', () {
      expect(applyMemoryQuery(memories).map((m) => m.id), ['2', '1', '3']);
      expect(
        applyMemoryQuery(memories, sort: MemorySort.oldest).map((m) => m.id),
        ['3', '1', '2'],
      );
      expect(
        applyMemoryQuery(memories, sort: MemorySort.importance)
            .map((m) => m.id),
        ['2', '3', '1'],
      );
    });
  });

  group('MemoryStats', () {
    test('empty list gives zeros', () {
      final stats = MemoryStats.compute(const <Memory>[], DateTime(2025, 6, 1));
      expect(stats.total, 0);
      expect(stats.lastActivity, isNull);
      expect(stats.averageImportance, 0);
    });

    test('counts are computed from real memories', () {
      final now = DateTime(2025, 6, 15, 12);
      final stats = MemoryStats.compute(<Memory>[
        buildMemory(id: '1', createdAt: now.subtract(const Duration(hours: 1))),
        buildMemory(
          id: '2',
          categoryId: 'goals',
          importance: 5,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        buildMemory(
          id: '3',
          categoryId: 'goals',
          createdAt: now.subtract(const Duration(days: 20)),
        ),
        buildMemory(
          id: '4',
          createdAt: DateTime(2024, 1, 1),
        ),
      ], now);

      expect(stats.total, 4);
      expect(stats.perCategory['goals'], 2);
      expect(stats.perCategory['life'], 2);
      expect(stats.addedToday, 1);
      expect(stats.addedLast7Days, 2);
      expect(stats.addedLast30Days, 3);
      expect(stats.addedThisYear, 3);
      expect(stats.categoriesInUse, 2);
      expect(stats.lastActivity, now.subtract(const Duration(hours: 1)));
    });
  });
}
