import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_tracker/core/date_utils.dart';
import '../domain/habit_style.dart';
import '../domain/streak_calculator.dart';
import 'habit_form_page.dart';
import 'habit_providers.dart';
import '../domain/weekday_utils.dart';

class HabitDetailPage extends ConsumerStatefulWidget {
  final int habitId;
  const HabitDetailPage({super.key, required this.habitId});

  @override
  ConsumerState<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends ConsumerState<HabitDetailPage> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  Future<void> _confirmArchive(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('封存習慣'),
        content: Text('「$name」將從今日清單移除，歷史紀錄會保留。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('封存')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(todayProvider.notifier).archive(widget.habitId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(habitDetailProvider(widget.habitId));

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: AppBar(), body: Center(child: Text('載入失敗：$e'))),
      data: (d) {
        final habit = d.habit;
        final color = Color(habit.colorValue);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todayKey = toDateKey(today);
        final doneToday = d.completedKeys.contains(todayKey);
        final current = StreakCalculator.current(d.completedKeys, now);
        final longest = StreakCalculator.longest(d.completedKeys);
        final start = DateTime.parse(habit.startDate);
        final selected = _selected ?? today;
        final selectedKey = toDateKey(selected);
        final selectedDone = d.completedKeys.contains(selectedKey);
        final selectedIsToday = selectedKey == todayKey;

        return Scaffold(
          appBar: AppBar(
            title: Text(habit.name, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: '編輯',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => HabitFormPage(habit: habit)),
                ),
              ),
              IconButton(
                tooltip: '封存',
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => _confirmArchive(habit.name),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // 標題區
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(iconFor(habit.iconKey), color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.description ?? weekdaysLabel(habit.weekdays),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (habit.remindTime != null) ...[
                          const SizedBox(height: 4),
                          Text('⏰ 每天 ${weekdaysLabel(habit.weekdays)} ${habit.remindTime} 提醒',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 統計
              Row(
                children: [
                  _StatBox(label: '目前連續', value: '🔥 $current 天'),
                  const SizedBox(width: 8),
                  _StatBox(label: '最長連續', value: '🏆 $longest 天'),
                  const SizedBox(width: 8),
                  _StatBox(
                      label: '總完成', value: '${d.completedKeys.length} 次'),
                ],
              ),
              const SizedBox(height: 16),

              // 今日打卡按鈕
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: doneToday ? Colors.grey : color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(doneToday ? Icons.undo : Icons.check),
                label: Text(doneToday ? '取消今日完成' : '完成今日'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(todayProvider.notifier)
                      .toggle(habit.id!, doneToday);
                },
              ),
              const SizedBox(height: 16),

              // 日曆
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: TableCalendar(
                  locale: 'zh_TW',
                  firstDay: start,
                  lastDay: today, // 未來日期不可選
                  focusedDay: _focused.isAfter(today) ? today : _focused,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  availableCalendarFormats: const {
                    CalendarFormat.month: '月'
                  },
                  selectedDayPredicate: (day) => isSameDay(day, selected),
                  onDaySelected: (sel, foc) => setState(() {
                    _selected = sel;
                    _focused = foc;
                  }),
                  onPageChanged: (foc) => _focused = foc,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (ctx, day, _) => _DayCell(
                      day: day,
                      color: color,
                      done: d.completedKeys.contains(toDateKey(day)),
                      scheduled: weekdayRuns(habit.weekdays, day.weekday),
                    ),
                    todayBuilder: (ctx, day, _) => _DayCell(
                      day: day,
                      color: color,
                      done: d.completedKeys.contains(toDateKey(day)),
                      scheduled: weekdayRuns(habit.weekdays, day.weekday),
                      isToday: true,
                    ),
                    selectedBuilder: (ctx, day, _) => _DayCell(
                      day: day,
                      color: color,
                      done: d.completedKeys.contains(toDateKey(day)),
                      scheduled: weekdayRuns(habit.weekdays, day.weekday),
                      isToday: isSameDay(day, today),
                      isSelected: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 所選日期狀態（文字，不只靠顏色）
              Center(
                child: Text(
                  '$selectedKey：${selectedDone ? "✅ 已完成" : "尚未完成"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),

              // 補打／取消所選日期（今天已有上方按鈕，這裡只處理過去日期）
              if (!selectedIsToday)
                OutlinedButton.icon(
                  icon: Icon(selectedDone ? Icons.undo : Icons.edit_calendar),
                  label: Text(selectedDone ? '取消這天的完成' : '補打這天'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(todayProvider.notifier)
                        .setDone(habit.id!, selectedKey, !selectedDone);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final Color color;
  final bool done;
  final bool scheduled;
  final bool isToday;
  final bool isSelected;

  const _DayCell({
    required this.day,
    required this.color,
    required this.done,
    this.scheduled = true,
    this.isToday = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // 非排程日淡化;但如果那天有打卡,仍維持上色
    final dim = !scheduled && !done;
    return Container(
      margin: const EdgeInsets.all(5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color : null,
        border: isSelected
            ? Border.all(color: onSurface, width: 2)
            : isToday
                ? Border.all(color: color, width: 2)
                : null,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: done
              ? Colors.white
              : dim
                  ? onSurface.withValues(alpha: 0.3)
                  : onSurface,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

