import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_tracker/core/date_utils.dart';
import '../../../core/glass_kit.dart';
import '../domain/habit_style.dart';
import '../domain/streak_calculator.dart';
import '../domain/weekday_utils.dart';
import 'habit_form_page.dart';
import 'habit_providers.dart';

Color _onColor(Color c) =>
    c.computeLuminance() > 0.6 ? Colors.black87 : Colors.white;

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
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => GlassScaffold(
          appBar: AppBar(),
          body: const SizedBox.shrink(),
    ),
      error: (e, _) => GlassScaffold(
          appBar: AppBar(), body: Center(child: Text('載入失敗：$e'))),
      data: (d) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final habit = d.habit;
        final color = Color(habit.colorValue);
        final onColor = _onColor(color);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todayKey = toDateKey(today);
        final doneToday = d.completedKeys.contains(todayKey);
        final current = StreakCalculator.current(
          d.completedKeys,
          now,
          weekdays: habit.weekdays,
        );
        final longest = StreakCalculator.longest(
          d.completedKeys,
          weekdays: habit.weekdays,
        );
        final start = DateTime.parse(habit.startDate);
        final selected = _selected ?? today;
        final selectedKey = toDateKey(selected);
        final selectedDone = d.completedKeys.contains(selectedKey);
        final selectedIsToday = selectedKey == todayKey;
        final selectedScheduled =
            weekdayRuns(habit.weekdays, selected.weekday);
        final todayScheduled = weekdayRuns(habit.weekdays, today.weekday);

        final schedule = weekdaysLabel(habit.weekdays);

        return GlassScaffold(
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // 標題區
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: color.withValues(alpha: 0.18),
                      child: Icon(iconFor(habit.iconKey), color: color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (habit.description != null &&
                              habit.description!.isNotEmpty) ...[
                            Text(habit.description!,
                                style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            '🗓 $schedule',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant),
                          ),
                          if (habit.remindTime != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '⏰ ${habit.remindTime} 提醒',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
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
              SizedBox(
                height: 52,
                child: doneToday
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                        ),
                        icon: const Icon(Icons.undo),
                        label: const Text('取消今日完成'),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(todayProvider.notifier)
                              .toggle(habit.id!, doneToday);
                        },
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: onColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                        ),
                        icon: const Icon(Icons.check),
                        label: Text(todayScheduled ? '完成今日' : '今天休息，仍要打卡'),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(todayProvider.notifier)
                              .toggle(habit.id!, doneToday);
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // 日曆
              GlassContainer(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: TableCalendar(
                  locale: 'zh_TW',
                  firstDay: start,
                  lastDay: today, // 未來日期不可選
                  focusedDay: _focused.isAfter(today) ? today : _focused,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  availableCalendarFormats: const {
                    CalendarFormat.month: '月'
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: theme.textTheme.titleMedium!,
                  ),
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
                  '$selectedKey：${selectedDone ? "✅ 已完成" : "尚未完成"}'
                  '${selectedScheduled ? "" : "（非排程日）"}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),

              // 補打／取消所選日期（今天已有上方按鈕，這裡只處理過去日期）
              if (!selectedIsToday)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  icon: Icon(
                      selectedDone ? Icons.undo : Icons.edit_calendar),
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
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        label: '$label $value',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
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
              ? _onColor(color)
              : dim
                  ? onSurface.withValues(alpha: 0.3)
                  : onSurface,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}