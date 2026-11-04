import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/locale_provider.dart';
import 'package:habit_tracker/core/widget_service.dart';
import '../../../core/date_utils.dart';
import '../../../core/notification_service.dart';
import '../data/habit_repository.dart';
import '../domain/habit.dart';
import '../domain/streak_calculator.dart';

final habitRepositoryProvider = Provider((ref) => HabitRepository());

/// 依目標從次數表算出「達標日」
Set<String> _completedFrom(Map<String, int> counts, int target) => {
      for (final e in counts.entries)
        if (e.value >= target) e.key,
    };

class HabitItem {
  final Habit habit;
  final bool doneToday; // 今天是否達標
  final int todayCount; // 今天已做幾次(沒紀錄為 0)
  final int currentStreak;
  final int longestStreak;

  const HabitItem({
    required this.habit,
    required this.doneToday,
    this.todayCount = 0,
    required this.currentStreak,
    required this.longestStreak,
  });
}

/// 詳情頁資料
class HabitDetail {
  final Habit habit;
  final Set<String> completedKeys; // 達標的日期
  final Map<String, int> counts; // 每個有紀錄日期的次數(含未達標)
  const HabitDetail(this.habit, this.completedKeys,
      [this.counts = const {}]);
}

class TodayNotifier extends AsyncNotifier<List<HabitItem>> {
  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  @override
  Future<List<HabitItem>> build() async {
    // watch：切換語言時重新載入，小工具文字跟著換
    final locale = ref.watch(localeProvider);
    final zh = locale.languageCode == 'zh';
    final items = await _load();
    _syncNotifications(items.map((e) => e.habit).toList(), zh);
    _syncWidget(items, zh);
    return items;
  }
  
  void _syncWidget(List<HabitItem> items, bool zh) {
    final now = DateTime.now();
    final list = items
        .where((e) => e.habit.runsOn(now.weekday))
        .map((e) => WidgetItem(
              e.habit.name,
              e.doneToday ? e.habit.dailyTarget : e.todayCount,
              e.habit.dailyTarget,
            ))
        .toList();
    WidgetService.instance.sync(list, toDateKey(now), zh: zh);
  }


  /// 重排提醒:失敗不應影響主要功能
  void _syncNotifications(List<Habit> habits, bool zh) {
    NotificationService.instance.syncAll(habits, zh: zh).catchError((_) {});
  }

  Future<List<HabitItem>> _load() async {
    final now = DateTime.now();
    final todayKey = toDateKey(now);
    final habits = await _repo.getActiveHabits();

    final items = <HabitItem>[];
    for (final h in habits) {
      final counts = await _repo.getLogCounts(h.id!);
      final keys = _completedFrom(counts, h.dailyTarget);
      items.add(HabitItem(
        habit: h,
        doneToday: keys.contains(todayKey),
        todayCount: counts[todayKey] ?? 0,
        currentStreak: StreakCalculator.current(keys, now, weekdays: h.weekdays),
        longestStreak: StreakCalculator.longest(keys, weekdays: h.weekdays),
      ));
    }
    return items;
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    ref.invalidate(habitDetailProvider);
    ref.invalidate(archivedProvider);
    await future;
  }

  Future<void> add({
    required String name,
    String? description,
    required String iconKey,
    required int colorValue,
    String? remindTime,
    int weekdays = Habit.allDays,
    int dailyTarget = 1,
  }) async {
    await _repo.addHabit(Habit(
      name: name.trim(),
      description: description?.trim().isEmpty ?? true
          ? null
          : description!.trim(),
      iconKey: iconKey,
      colorValue: colorValue,
      startDate: toDateKey(DateTime.now()),
      remindTime: remindTime,
      weekdays: weekdays,
      dailyTarget: dailyTarget.clamp(1, Habit.maxDailyTarget),
    ));
    await _reload();
  }

  Future<void> updateHabit(Habit habit) async {
    await _repo.updateHabit(habit);
    await _reload();
  }

  Future<void> archive(int id) async {
    await _repo.archiveHabit(id);
    await _reload();
  }

  Future<void> restore(int id) async {
    await _repo.unarchiveHabit(id);
    await _reload();
  }

  Future<void> deleteHabit(int id) async {
    await _repo.deleteHabit(id);
    await _reload();
  }

  /// 單次習慣:切換今天的完成狀態
  Future<void> toggle(int habitId, bool doneToday) async {
    final todayKey = toDateKey(DateTime.now());
    if (doneToday) {
      await _repo.uncomplete(habitId, todayKey);
    } else {
      await _repo.complete(habitId, todayKey);
    }
    await _reload();
  }

  /// 多次習慣:次數 +1。[dateKey] 省略代表今天,不允許未來日期
  Future<void> increment(int habitId, [String? dateKey]) async {
    final today = toDateKey(DateTime.now());
    final key = dateKey ?? today;
    if (key.compareTo(today) > 0) return;
    await _repo.increment(habitId, key);
    await _reload();
  }

  /// 多次習慣:次數 -1。[dateKey] 省略代表今天
  Future<void> decrement(int habitId, [String? dateKey]) async {
    final today = toDateKey(DateTime.now());
    final key = dateKey ?? today;
    if (key.compareTo(today) > 0) return;
    await _repo.decrement(habitId, key);
    await _reload();
  }

  /// 設定任一日期的完成狀態(補打用),不允許未來日期
  Future<void> setDone(int habitId, String dateKey, bool done) async {
    final today = toDateKey(DateTime.now());
    if (dateKey.compareTo(today) > 0) return;
    if (done) {
      await _repo.complete(habitId, dateKey);
    } else {
      await _repo.uncomplete(habitId, dateKey);
    }
    await _reload();
  }

  /// 拖曳排序:先更新畫面,再寫入資料庫
  Future<void> reorder(int oldIndex, int newIndex) async {
    final items = [...(state.value ?? <HabitItem>[])];
    if (oldIndex < 0 || oldIndex >= items.length) return;
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    state = AsyncData(items);
    await _repo.updateOrder(items.map((e) => e.habit.id!).toList());
  }

  /// 只重排「今天可見」的習慣,隱藏的習慣維持原位置
  Future<void> reorderVisible(List<int> visibleIdsInNewOrder) async {
    final items = [...(state.value ?? <HabitItem>[])];
    final visibleSet = visibleIdsInNewOrder.toSet();
    final byId = {for (final e in items) e.habit.id!: e};
    final queue = visibleIdsInNewOrder.iterator;

    final result = <HabitItem>[];
    for (final e in items) {
      if (visibleSet.contains(e.habit.id)) {
        queue.moveNext();
        result.add(byId[queue.current]!);
      } else {
        result.add(e);
      }
    }
    state = AsyncData(result);
    await _repo.updateOrder(result.map((e) => e.habit.id!).toList());
  }

  Future<DeletedHabitSnapshot?> deleteWithSnapshot(int id) async {
    final snap = await _repo.deleteHabitWithSnapshot(id);
    await _reload();
    return snap;
  }

  Future<void> restoreDeleted(DeletedHabitSnapshot snap) async {
    await _repo.restoreSnapshot(snap);
    await _reload();
  }

  Future<void> refresh() => _reload();
}

final todayProvider =
    AsyncNotifierProvider<TodayNotifier, List<HabitItem>>(TodayNotifier.new);

final habitDetailProvider =
    FutureProvider.family<HabitDetail, int>((ref, habitId) async {
  final repo = ref.read(habitRepositoryProvider);
  final habit = await repo.getHabit(habitId);
  if (habit == null) throw StateError('找不到習慣');
  final counts = await repo.getLogCounts(habitId);
  return HabitDetail(
    habit,
    _completedFrom(counts, habit.dailyTarget),
    counts,
  );
});

final archivedProvider = FutureProvider<List<Habit>>((ref) {
  return ref.watch(habitRepositoryProvider).getArchivedHabits();
});
