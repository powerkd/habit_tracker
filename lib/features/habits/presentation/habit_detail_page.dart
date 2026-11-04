import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_tracker/core/date_utils.dart';
import '../../../core/app_settings.dart';
import '../../../core/glass_kit.dart';
import '../../../core/haptics.dart';
import '../../../core/motion.dart';
import '../../../core/strings.dart';
import '../../../core/tokens.dart';
import '../domain/habit_style.dart';
import '../domain/streak_calculator.dart';
import '../domain/weekday_utils.dart';
import 'habit_form_page.dart';
import 'habit_providers.dart';

Color _onColor(Color c) =>
    c.computeLuminance() > 0.6 ? Colors.black87 : Colors.white;

/// iOS 風格純色卡片:無邊框、無陰影
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: IosColors.of(context).card,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: child,
    );
  }
}

class HabitDetailPage extends ConsumerStatefulWidget {
  final int habitId;

  /// 從今天頁帶入的預覽資訊,讓資料載入前 Hero 就有目標
  final String? previewIconKey;
  final Color? previewColor;

  const HabitDetailPage({
    super.key,
    required this.habitId,
    this.previewIconKey,
    this.previewColor,
  });

  @override
  ConsumerState<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends ConsumerState<HabitDetailPage> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  Widget _heroIcon(IconData icon, Color color) => Hero(
        tag: 'habit_icon_${widget.habitId}',
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(Radii.tile + 2),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
      );

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
    final c = IosColors.of(context);
    final done = count >= target;
    return _Card(
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
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: c.labelSecondary)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count／$target',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (done) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle_rounded,
                            size: 20, color: color),
                      ],
                    ],
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
    final mondayStart =
        ref.watch(appSettingsProvider.select((v) => v.mondayStart));

    return async.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => GlassScaffold(
        appBar: AppBar(),
        body: widget.previewIconKey == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  _Card(
                    child: Row(children: [
                      _heroIcon(
                        iconFor(widget.previewIconKey!),
                        widget.previewColor ?? kAccent,
                      ),
                    ]),
                  ),
                ],
              ),
      ),
      error: (e, _) => GlassScaffold(
          appBar: AppBar(), body: Center(child: Text(s.loadFailed(e)))),
      data: (d) {
        final theme = Theme.of(context);
        final c = IosColors.of(context);
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
              _Card(
                child: Row(
                  children: [
                    _heroIcon(iconFor(habit.iconKey), color),
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
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 14, color: c.labelSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  schedule,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: c.labelSecondary),
                                ),
                              ),
                            ],
                          ),
                          if (multi) ...[
                            const SizedBox(height: 2),
                            Text(
                              s.targetPerDay(target),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: c.labelSecondary),
                            ),
                          ],
                          if (habit.remindTime != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              s.remindAt(habit.remindTime!),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: c.labelSecondary),
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
                    value: s.daysValue(current),
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Tone.fire,
                  ),
                  const SizedBox(width: 8),
                  _StatBox(
                    label: s.longestStreakLabel,
                    value: s.daysValue(longest),
                    icon: Icons.emoji_events_rounded,
                    iconColor: Tone.trophy,
                  ),
                  const SizedBox(width: 8),
                  _StatBox(
                    label: s.totalDoneLabel,
                    value: s.timesValue(d.completedKeys.length),
                    icon: Icons.check_circle_rounded,
                    iconColor: color,
                  ),
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
                          Haptics.light();
                          ref
                              .read(todayProvider.notifier)
                              .decrement(habit.id!);
                        }
                      : null,
                  onPlus: doneToday
                      ? null
                      : () {
                          Haptics.light();
                          ref
                              .read(todayProvider.notifier)
                              .increment(habit.id!);
                        },
                )
              else
                SizedBox(
                  height: 52,
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.normal),
                    switchInCurve: Motion.enter,
                    switchOutCurve: Motion.exit,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                        child: child,
                      ),
                    ),
                    child: doneToday
                        ? OutlinedButton.icon(
                            key: const ValueKey('undo'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            icon: const Icon(Icons.undo),
                            label: Text(s.cancelToday),
                            onPressed: () {
                              Haptics.light();
                              ref
                                  .read(todayProvider.notifier)
                                  .toggle(habit.id!, doneToday);
                            },
                          )
                        : FilledButton.icon(
                            key: const ValueKey('do'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: color,
                              foregroundColor: onColor,
                            ),
                            icon: const Icon(Icons.check),
                            label: Text(todayScheduled
                                ? s.completeToday
                                : s.restDayStillCheck),
                            onPressed: () {
                              Haptics.light();
                              ref
                                  .read(todayProvider.notifier)
                                  .toggle(habit.id!, doneToday);
                            },
                          ),
                  ),
                ),
              const SizedBox(height: 16),

              // 日曆
              _Card(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: TableCalendar(
                  locale: Localizations.localeOf(context).toString(),
                  firstDay: start,
                  lastDay: today, // 未來日期不可選
                  focusedDay: _focused.isAfter(today) ? today : _focused,
                  startingDayOfWeek: mondayStart
                      ? StartingDayOfWeek.monday
                      : StartingDayOfWeek.sunday,
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
                    todayBuilder: (ctx, day, _) => cell(day, isToday: true),
                    selectedBuilder: (ctx, day, _) => cell(
                      day,
                      isToday: isSameDay(day, today),
                      isSelected: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 所選日期狀態(文字,不只靠顏色)
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
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: c.labelSecondary),
                ),
              ),
              const SizedBox(height: 8),

              // 補打/取消所選日期(今天已有上方控制,這裡只處理過去日期)
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
                            Haptics.light();
                            ref
                                .read(todayProvider.notifier)
                                .decrement(habit.id!, selectedKey);
                          }
                        : null,
                    onPlus: selectedDone
                        ? null
                        : () {
                            Haptics.light();
                            ref
                                .read(todayProvider.notifier)
                                .increment(habit.id!, selectedKey);
                          },
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon:
                        Icon(selectedDone ? Icons.undo : Icons.edit_calendar),
                    label: Text(selectedDone ? s.cancelThatDay : s.makeUp),
                    onPressed: () {
                      Haptics.light();
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
  final IconData icon;
  final Color iconColor;
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = IosColors.of(context);
    return Expanded(
      child: Semantics(
        label: '$label $value',
        excludeSemantics: true,
        child: _Card(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 4),
                    Text(
                      value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(color: c.labelSecondary, fontSize: 12),
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
