import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/habits/domain/habit.dart';
import 'package:habit_tracker/features/habits/presentation/habit_providers.dart';
import 'package:habit_tracker/features/habits/presentation/today_page.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeTodayNotifier extends TodayNotifier {
  final List<HabitItem> items;
  final List<int> toggled;
  FakeTodayNotifier(this.items, this.toggled);

  @override
  Future<List<HabitItem>> build() async => items;

  @override
  Future<void> toggle(int habitId, bool doneToday) async {
    toggled.add(habitId);
  }
}

HabitItem item(int id, String name, {bool done = false, int streak = 0}) {
  return HabitItem(
    habit: Habit(id: id, name: name, startDate: '2026-11-01'),
    doneToday: done,
    currentStreak: streak,
    longestStreak: streak,
  );
}

Widget buildApp(List<HabitItem> items, List<int> toggled) {
  return ProviderScope(
    overrides: [
      todayProvider
          .overrideWith(() => FakeTodayNotifier(items, toggled)),
    ],
    child: const MaterialApp(home: TodayPage()),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_TW');
  });

  testWidgets('沒有習慣時顯示空白引導', (tester) async {
    await tester.pumpWidget(buildApp([], []));
    await tester.pumpAndSettle();

    expect(find.textContaining('還沒有習慣'), findsOneWidget);
  });

  testWidgets('顯示習慣名稱、進度與連續天數', (tester) async {
    await tester.pumpWidget(buildApp([
      item(1, '閱讀', done: true, streak: 3),
      item(2, '跑步'),
    ], []));
    await tester.pumpAndSettle();

    expect(find.text('閱讀'), findsOneWidget);
    expect(find.text('跑步'), findsOneWidget);
    expect(find.text('已完成 1／2'), findsOneWidget);
    expect(find.textContaining('連續 3 天'), findsOneWidget);
  });

  testWidgets('點圓圈會呼叫 toggle', (tester) async {
    final toggled = <int>[];
    await tester.pumpWidget(buildApp([item(7, '喝水')], toggled));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('標記完成'));
    await tester.pump();

    expect(toggled, [7]);
  });

  testWidgets('已完成的習慣顯示「取消完成」按鈕', (tester) async {
    await tester.pumpWidget(buildApp([item(1, '閱讀', done: true)], []));
    await tester.pumpAndSettle();

    expect(find.byTooltip('取消完成'), findsOneWidget);
    expect(find.byTooltip('標記完成'), findsNothing);
  });

  testWidgets('首頁有新增習慣與設定按鈕', (tester) async {
    await tester.pumpWidget(buildApp([], []));
    await tester.pumpAndSettle();

    expect(find.text('新增習慣'), findsOneWidget);
    expect(find.byTooltip('設定'), findsOneWidget);
  });
}
