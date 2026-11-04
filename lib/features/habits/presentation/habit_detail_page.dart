import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_tracker/core/date_utils.dart';
import '../../../core/glass_kit.dart';
import '../../../core/strings.dart';
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
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.archiveTitle),
        content: Text(s.archiveBody(name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.archiveBtn)),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(todayProvider.notifier).archive(widget.habitId);
      if (mounted) Navigator.pop(context);
    }
  }

  /// 多次習慣的計數列:標題 + 次數 + − / ＋
  Widget _buildCounter({
    required String label,
    required int count,
    required int target,
    required Color color,
    required Color onColor,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
  }) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final done = count >= target;
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: s.counterSemantic(label, count, target),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(
                    done ? '$count／$target ✅' : '$count／$target',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: s.decrease,
            iconSize: 28,
            onPressed: onMinus,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          const SizedBox(width: 4),
          IconButton.filled(
            tooltip: done ? s.reached : s.doOnce,
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor: color,
              foregroundColor: onColor,
              disabledBackgroundColor: color.withValues(alpha: 0.35),
              disabledForegroundColor: onColor.withValues(alpha: 0.7),
            ),
            onPressed: onPlus,
            icon: Icon(done ? Icons.check : Icons.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final async = ref.watch(habitDetailProvider(widget.habitId));

    return async.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () =>
          GlassScaffold(appBar: AppBar(), body: const SizedBox.shrink()),
      error: (e, _) => GlassScaffold(
          appBar: AppBar(), body: Center(child: Text(s.loadFailed(e)))),
      data: (d) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final habit = d.habit;
        final color = Color(habit.colorValue);
        final onColor = _onColor(color);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todayKey = toDateKey(today);
        final target = habit.dailyTarget;
        final multi = habit.isMulti;

        final doneToday = d.completedKeys.contains(todayKey);
        final todayCount = d.counts[todayKey] ?? 0;
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
        final selectedCount = d.counts[selectedKey] ?? 0;
        final selectedIsToday = selectedKey == todayKey;
        final selectedScheduled =
            weekdayRuns(habit.weekdays, selected.weekday);
        final todayScheduled = weekdayRuns(habit.weekdays, today.weekday);

        final schedule = s.scheduleLabel(habit.weekdays);

        /// 日曆格:達標、部分完成、排程
        Widget cell(DateTime day,
                {bool isToday = false, bool isSelected = false}) =>
            _DayCell(
              day: day,
              color: color,
              done: d.completedKeys.contains(toDateKey(day)),
              partial: !d.completedKeys.contains(toDateKey(day)) &&
                  (d.counts[toDateKey(day)] ?? 0) > 0,
              scheduled: weekdayRuns(habit.weekdays, day.weekday),
              isToday: isToday,
              isSelected: isSelected,
            );

        return GlassScaffold(
          appBar: AppBar(
            title: Text(habit.name, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: s.edit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => HabitFormPage(habit: habit)),
                ),
              ),
              IconButton(
                tooltip: s.archiveBtn,
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
                            '\u{1F5D3} $schedule',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant),
                          ),
                          if (multi) ...[
                            const SizedBox(height: 2),
                            Text(
                              s.targetPerDay(target),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant),
                            ),
                          ],
                          if (habit.remindTime != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              s.remindAt(habit.remindTime!),
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
                  _StatBox(
                      label: s.currentStreakLabel,
                      value: '\u{1F525} ${s.daysValue(current)}'),
                  const SizedBox(width: 8),
                  _StatBox(
                      label: s.longestStreakLabel,
                      value: '\u{1F3C6} ${s.daysValue(longest)}'),
                  const SizedBox(width: 8),
                  _StatBox(
                      label: s.totalDoneLabel,
                      value: s.timesValue(d.completedKeys.length)),
                ],
              ),
              const SizedBox(height: 16),

              // 今日打卡
              if (multi)
                _buildCounter(
                  label: todayScheduled ? s.today : s.todayRestDay,
                  count: todayCount,
                  target: target,
                  color: color,
                  onColor: onColor,
                  onMinus: todayCount > 0
                      ? () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(todayProvider.notifier)
                              .decrement(habit.id!);
                        }
                      : null,
                  onPlus: doneToday
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(todayProvider.notifier)
                              .increment(habit.id!);
                        },
                )
              else
                SizedBox(
                  height: 52,
                  child: doneToday
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26)),
                          ),
                          icon: const Icon(Icons.undo),
                          label: Text(s.cancelToday),
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
                          label: Text(todayScheduled
                              ? s.completeToday
                              : s.restDayStillCheck),
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
                  locale: Localizations.localeOf(context).toString(),
                  firstDay: start,
                  lastDay: today, // 未來日期不可選
                  focusedDay: _focused.isAfter(today) ? today : _focused,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  availableCalendarFormats: {
                    CalendarFormat.month: s.monthFormat,
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
                    defaultBuilder: (ctx, day, _) => cell(day),
                    todayBuilder: (ctx, day, _) =>
                        cell(day, isToday: true),
                    selectedBuilder: (ctx, day, _) => cell(
                      day,
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
                  s.dayStatus(
                    key: selectedKey,
                    done: selectedDone,
                    multi: multi,
                    count: selectedCount,
                    target: target,
                    scheduled: selectedScheduled,
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),

              // 補打／取消所選日期（今天已有上方控制，這裡只處理過去日期）
              if (!selectedIsToday)
                if (multi)
                  _buildCounter(
                    label: selectedKey,
                    count: selectedCount,
                    target: target,
                    color: color,
                    onColor: onColor,
                    onMinus: selectedCount > 0
                        ? () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(todayProvider.notifier)
                                .decrement(habit.id!, selectedKey);
                          }
                        : null,
                    onPlus: selectedDone
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(todayProvider.notifier)
                                .increment(habit.id!, selectedKey);
                          },
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: Icon(
                        selectedDone ? Icons.undo : Icons.edit_calendar),
                    label:
                        Text(selectedDone ? s.cancelThatDay : s.makeUp),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 12),
                ),
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
  final bool done; // 達標
  final bool partial; // 有紀錄但未達標
  final bool scheduled;
  final bool isToday;
  final bool isSelected;

  const _DayCell({
    required this.day,
    required this.color,
    required this.done,
    this.partial = false,
    this.scheduled = true,
    this.isToday = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // 非排程日淡化;但如果那天有紀錄,仍維持正常顏色
    final dim = !scheduled && !done && !partial;
    return Container(
      margin: const EdgeInsets.all(5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? color
            : partial
                ? color.withValues(alpha: 0.28)
                : null,
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
