import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/date_utils.dart';
import '../../../core/notification_service.dart';
import '../data/habit_repository.dart';
import '../domain/habit.dart';
import '../domain/streak_calculator.dart';

final habitRepositoryProvider = Provider((ref) => HabitRepository());

class HabitItem {
  final Habit habit;
  final bool doneToday;
  final int currentStreak;
  final int longestStreak;

  const HabitItem({
    required this.habit,
    required this.doneToday,
    required this.currentStreak,
    required this.longestStreak,
  });
}

/// 詳情頁資料
class HabitDetail {
  final Habit habit;
  final Set<String> completedKeys;
  const HabitDetail(this.habit, this.completedKeys);
}

class TodayNotifier extends AsyncNotifier<List<HabitItem>> {
  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  @override
  Future<List<HabitItem>> build() => _load();

  Future<List<HabitItem>> _load() async {
    final now = DateTime.now();
    final todayKey = toDateKey(now);
    final habits = await _repo.getActiveHabits();

    final items = <HabitItem>[];
    for (final h in habits) {
      final keys = await _repo.getCompletedKeys(h.id!);
      items.add(HabitItem(
        habit: h,
        doneToday: keys.contains(todayKey),
        currentStreak: StreakCalculator.current(keys, now),
        longestStreak: StreakCalculator.longest(keys),
      ));
    }
    return items;
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    ref.invalidate(habitDetailProvider);
    ref.invalidate(archivedProvider);
    await future;
    // 重排提醒:失敗不應影響主要功能
    try {
      final habits = await _repo.getActiveHabits();
      await NotificationService.instance.syncAll(habits);
    } catch (_) {}
  }

  Future<void> add({
    required String name,
    String? description,
    required String iconKey,
    required int colorValue,
    String? remindTime, // 新增
  }) async {
    await _repo.addHabit(Habit(
      name: name.trim(),
      description: description?.trim().isEmpty ?? true
          ? null
          : description!.trim(),
      iconKey: iconKey,
      colorValue: colorValue,
      startDate: toDateKey(DateTime.now()),
      remindTime: remindTime, // 新增
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

  Future<void> toggle(int habitId, bool doneToday) async {
    final todayKey = toDateKey(DateTime.now());
    if (doneToday) {
      await _repo.uncomplete(habitId, todayKey);
    } else {
      await _repo.complete(habitId, todayKey);
    }
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
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    state = AsyncData(items);
    await _repo.updateOrder(items.map((e) => e.habit.id!).toList());
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
  final keys = await repo.getCompletedKeys(habitId);
  return HabitDetail(habit, keys);
});

final archivedProvider = FutureProvider<List<Habit>>((ref) {
  return ref.watch(habitRepositoryProvider).getArchivedHabits();
});
