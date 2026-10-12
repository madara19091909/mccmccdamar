import 'package:echo/app.dart';
import 'package:echo/data/models/memory.dart';
import 'package:echo/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fakes.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  List<Memory> memories = const <Memory>[],
}) async {
  tester.view.physicalSize = const Size(1080, 2200);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  // Light-effects mode stops the endless world animation so pumpAndSettle ends.
  final repository = InMemoryMemoryRepository(
    memories: memories,
    settings: <String, String>{SettingsController.lightEffectsKey: '1'},
  );
  await tester.pumpWidget(
    EchoApp(repository: repository, imageStore: FakeImageStore()),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  testWidgets('starts on the home world with empty state and navigation',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('عالم ECHO'), findsOneWidget);
    expect(find.text('عالمك ينتظر أول ذكرى'), findsOneWidget);
    expect(find.text('العالم'), findsOneWidget);
    expect(find.text('استكشاف'), findsOneWidget);
    expect(find.text('إحصائيات'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.byKey(const Key('add_memory_fab')), findsOneWidget);
  });

  testWidgets('the UI is right-to-left', (tester) async {
    await pumpApp(tester);
    final context = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('the add button opens the memory form', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('add_memory_fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memory_title_field')), findsOneWidget);
    expect(find.byKey(const Key('save_memory_button')), findsOneWidget);
  });

  testWidgets('saving without a title shows a validation error',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('add_memory_fab')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save_memory_button')));
    await tester.tap(find.byKey(const Key('save_memory_button')));
    await tester.pumpAndSettle();
    expect(find.text('العنوان مطلوب'), findsOneWidget);
    expect(find.byKey(const Key('memory_title_field')), findsOneWidget);
  });

  testWidgets('adds a memory and it appears on the home screen',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('add_memory_fab')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('memory_title_field')),
      'رحلة إلى الجبل',
    );
    await tester.enterText(
      find.byKey(const Key('memory_body_field')),
      'يوم لا يُنسى',
    );
    await tester.ensureVisible(find.byKey(const Key('save_memory_button')));
    await tester.tap(find.byKey(const Key('save_memory_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('memory_title_field')), findsNothing);
    expect(find.text('رحلة إلى الجبل'), findsOneWidget);
    expect(find.text('عالمك ينتظر أول ذكرى'), findsNothing);
  });

  testWidgets('edits and deletes an existing memory', (tester) async {
    await pumpApp(
      tester,
      memories: <Memory>[
        buildMemory(
          id: 'seed',
          title: 'ذكرى قديمة',
          body: 'نص أصلي',
          occurredAt: DateTime(2025, 4, 2, 9),
        ),
      ],
    );

    await tester.tap(find.text('استكشاف'));
    await tester.pumpAndSettle();
    expect(find.text('ذكرى قديمة'), findsOneWidget);

    await tester.tap(find.text('ذكرى قديمة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit_memory_button')), findsOneWidget);

    // Edit
    await tester.tap(find.byKey(const Key('edit_memory_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('memory_title_field')),
      'ذكرى معدّلة',
    );
    await tester.ensureVisible(find.byKey(const Key('save_memory_button')));
    await tester.tap(find.byKey(const Key('save_memory_button')));
    await tester.pumpAndSettle();
    expect(find.text('ذكرى معدّلة'), findsOneWidget);
    expect(find.text('ذكرى قديمة'), findsNothing);

    // Delete
    await tester.tap(find.byKey(const Key('delete_memory_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_button')));
    await tester.pumpAndSettle();

    expect(find.text('ذكرى معدّلة'), findsNothing);
    expect(find.text('لا توجد ذكريات بعد'), findsOneWidget);
  });

  testWidgets('explore search filters results and shows empty result state',
      (tester) async {
    await pumpApp(
      tester,
      memories: <Memory>[
        buildMemory(id: '1', title: 'قهوة الصباح'),
        buildMemory(
          id: '2',
          title: 'مشروع جديد',
          occurredAt: DateTime(2025, 2, 1),
        ),
      ],
    );
    await tester.tap(find.text('استكشاف'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('search_field')), 'قهوة');
    await tester.pumpAndSettle();
    expect(find.text('قهوة الصباح'), findsOneWidget);
    expect(find.text('مشروع جديد'), findsNothing);

    await tester.enterText(find.byKey(const Key('search_field')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('لا نتائج مطابقة'), findsOneWidget);
  });

  testWidgets('stats page shows real numbers and empty state',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('إحصائيات'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد إحصائيات بعد'), findsOneWidget);
  });

  testWidgets('stats page counts stored memories', (tester) async {
    await pumpApp(
      tester,
      memories: <Memory>[
        buildMemory(id: '1', createdAt: DateTime.now()),
        buildMemory(id: '2', createdAt: DateTime.now()),
      ],
    );
    await tester.tap(find.text('إحصائيات'));
    await tester.pumpAndSettle();
    expect(find.text('إحصائياتك'), findsOneWidget);
    expect(find.text('إجمالي الذكريات'), findsOneWidget);
    expect(find.text('متوسط الأهمية'), findsOneWidget);
  });

  testWidgets('settings page exposes theme, data and about sections',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('إعدادات ECHO'), findsOneWidget);
    expect(find.byKey(const Key('export_backup_tile')), findsOneWidget);
    expect(find.byKey(const Key('import_backup_tile')), findsOneWidget);
    expect(find.byKey(const Key('light_effects_switch')), findsOneWidget);
  });
}
