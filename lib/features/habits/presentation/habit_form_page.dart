import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/glass_kit.dart';
import '../../../core/haptics.dart';
import '../../../core/motion.dart';
import '../../../core/strings.dart';
import '../../../core/toast.dart';
import '../../../core/tokens.dart';
import '../domain/habit.dart';
import '../domain/habit_style.dart';
import '../domain/weekday_utils.dart';
import 'habit_providers.dart';

class HabitFormPage extends ConsumerStatefulWidget {
  /// 傳入 habit 代表編輯；null 代表新增
  final Habit? habit;
  const HabitFormPage({super.key, this.habit});

  @override
  ConsumerState<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends ConsumerState<HabitFormPage> {
  static const _maxDailyTarget = 20;

  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late String _iconKey;
  late int _colorValue;
  late int _weekdays;
  late int _dailyTarget;
  String? _remindTime; // "HH:mm"；null 代表不提醒
  bool _saving = false;
  bool _focusScheduled = false;

  bool get _isEdit => widget.habit != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEdit || _focusScheduled) return;
    _focusScheduled = true;

    final anim = ModalRoute.of(context)?.animation;
    if (anim == null || anim.isCompleted) {
      _nameFocus.requestFocus();
      return;
    }
    void listener(AnimationStatus s) {
      if (s == AnimationStatus.completed) {
        anim.removeStatusListener(listener);
        if (mounted) _nameFocus.requestFocus();
      }
    }

    anim.addStatusListener(listener);
  }

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _name = TextEditingController(text: h?.name ?? '');
    _desc = TextEditingController(text: h?.description ?? '');
    _iconKey = h?.iconKey ?? 'book';
    _colorValue = h?.colorValue ?? habitColors.first;
    _remindTime = h?.remindTime;
    _weekdays = h?.weekdays ?? allWeekdays;
    _dailyTarget = h?.dailyTarget ?? 1;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    _desc.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _remindTime != null
          ? _parseTime(_remindTime!)
          : const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _remindTime = _formatTime(picked));
    }
  }

  Future<void> _save() async {
    if (_saving) return; // 防止重複點擊
    if (!_formKey.currentState!.validate()) return;
    final s = S.of(context);
    // await 之前先取得 Overlay;頁面關閉後提示仍可顯示
    final overlay = Overlay.of(context, rootOverlay: true);

    if (_weekdays == 0) {
      Haptics.light();
      Toast.showOn(
        overlay,
        message: s.pickAtLeastOne,
        icon: Icons.error_outline_rounded,
        iconColor: Tone.danger,
      );
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(todayProvider.notifier);
    try {
      if (_isEdit) {
        final desc = _desc.text.trim();
        await notifier.updateHabit(Habit(
          id: widget.habit!.id,
          name: _name.text.trim(),
          description: desc.isEmpty ? null : desc,
          iconKey: _iconKey,
          colorValue: _colorValue,
          startDate: widget.habit!.startDate,
          isArchived: widget.habit!.isArchived,
          sortOrder: widget.habit!.sortOrder,
          remindTime: _remindTime,
          weekdays: _weekdays,
          dailyTarget: _dailyTarget,
        ));
      } else {
        await notifier.add(
          name: _name.text,
          description: _desc.text,
          iconKey: _iconKey,
          colorValue: _colorValue,
          remindTime: _remindTime,
          weekdays: _weekdays,
          dailyTarget: _dailyTarget,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      Toast.showOn(
        overlay,
        message: s.saveFailed(e),
        icon: Icons.error_outline_rounded,
        iconColor: Tone.danger,
      );
    }
  }

  /// 填色與圓角由 ThemeData.inputDecorationTheme 提供
  InputDecoration _dec(String label, {String? hint}) =>
      InputDecoration(labelText: label, hintText: hint);

  /// 區段:卡片外小灰字標題 + 純色卡片
  Widget _section(String title, Widget child) {
    final c = IosColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: Gap.lg),
          padding: const EdgeInsets.all(Gap.lg),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildDailyTargetSection(ThemeData theme) {
    final s = S.of(context);
    final c = IosColors.of(context);
    final editingHigher =
        _isEdit && _dailyTarget > (widget.habit?.dailyTarget ?? 1);
    return _section(
      s.dailyTimes,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.timesPerDay, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      _dailyTarget == 1
                          ? s.tapOnceDone
                          : s.doneAfter(_dailyTarget),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: c.labelSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: s.decreaseTimes,
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _dailyTarget > 1
                    ? () {
                        Haptics.selection();
                        setState(() => _dailyTarget--);
                      }
                    : null,
              ),
              SizedBox(
                width: 32,
                child: Semantics(
                  label: s.dailyTimesSemantic(_dailyTarget),
                  excludeSemantics: true,
                  child: Text(
                    '$_dailyTarget',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                tooltip: s.increaseTimes,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _dailyTarget < _maxDailyTarget
                    ? () {
                        Haptics.selection();
                        setState(() => _dailyTarget++);
                      }
                    : null,
              ),
            ],
          ),
          if (editingHigher)
            Padding(
              padding: const EdgeInsets.only(top: Gap.sm),
              child: Text(
                s.raiseWarn,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Tone.danger,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final color = Color(_colorValue);
    final onColor =
        color.computeLuminance() > 0.6 ? Colors.black87 : Colors.white;
    final colorChoices = habitColorChoices(widget.habit?.colorValue);

    return GlassScaffold(
      appBar: AppBar(title: Text(_isEdit ? s.editHabit : s.newHabit)),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _section(
              s.basicInfo,
              Column(
                children: [
                  TextFormField(
                    controller: _name,
                    maxLength: 30,
                    focusNode: _nameFocus,
                    decoration: _dec(s.habitName, hint: s.habitNameHint),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? s.nameRequired
                        : null,
                  ),
                  const SizedBox(height: Gap.md),
                  TextFormField(
                    controller: _desc,
                    maxLength: 100,
                    maxLines: 2,
                    decoration: _dec(s.descOptional),
                  ),
                ],
              ),
            ),
            _section(
              s.appearance,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.iconLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: Gap.sm),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final e in habitIcons.entries)
                        ChoiceChip(
                          label: Icon(e.value,
                              color: _iconKey == e.key ? onColor : null),
                          selected: _iconKey == e.key,
                          selectedColor: color,
                          showCheckmark: false,
                          onSelected: (_) {
                            Haptics.selection();
                            setState(() => _iconKey = e.key);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(s.colorLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: Gap.sm),
                  Wrap(
                    spacing: Gap.sm,
                    runSpacing: Gap.sm,
                    children: [
                      for (final c in colorChoices)
                        Semantics(
                          button: true,
                          selected: _colorValue == c,
                          label: s.colorLabel,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Haptics.selection();
                              setState(() => _colorValue = c);
                            },
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: AnimatedContainer(
                                  duration: Motion.of(context, Motion.fast),
                                  curve: Motion.enter,
                                  width: _colorValue == c ? 38 : 32,
                                  height: _colorValue == c ? 38 : 32,
                                  decoration: BoxDecoration(
                                    color: Color(c),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _colorValue == c
                                      ? Icon(
                                          Icons.check,
                                          size: 20,
                                          color: Color(c).computeLuminance() >
                                                  0.6
                                              ? Colors.black87
                                              : Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _buildDailyTargetSection(theme),
            _section(
              s.repeatAndRemind,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.repeat, style: theme.textTheme.titleMedium),
                  const SizedBox(height: Gap.md),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: _DayButton(
                            label: s.weekdayShort(i),
                            selected: (_weekdays >> i) & 1 == 1,
                            color: color,
                            onColor: onColor,
                            onTap: () {
                              Haptics.selection();
                              setState(() {
                                _weekdays = (_weekdays >> i) & 1 == 1
                                    ? _weekdays & ~(1 << i)
                                    : _weekdays | (1 << i);
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  Wrap(
                    spacing: Gap.sm,
                    children: [
                      ChoiceChip(
                        label: Text(s.everyDay),
                        selected: _weekdays == allWeekdays,
                        onSelected: (_) =>
                            setState(() => _weekdays = allWeekdays),
                      ),
                      ChoiceChip(
                        label: Text(s.weekdaysChip),
                        selected: _weekdays == workdays,
                        onSelected: (_) =>
                            setState(() => _weekdays = workdays),
                      ),
                      ChoiceChip(
                        label: Text(s.weekendChip),
                        selected: _weekdays == weekend,
                        onSelected: (_) =>
                            setState(() => _weekdays = weekend),
                      ),
                    ],
                  ),
                  if (_weekdays == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.sm),
                      child: Text(
                        s.pickAtLeastOne,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Tone.danger),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(s.reminder, style: theme.textTheme.titleMedium),
                  const SizedBox(height: Gap.xs),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.alarm, color: theme.colorScheme.primary),
                    title: Text(_remindTime ?? s.notSet),
                    subtitle: Text(s.tapPickTime),
                    onTap: _pickTime,
                    trailing: _remindTime == null
                        ? null
                        : IconButton(
                            tooltip: s.clearReminder,
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _remindTime = null),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: color,
                    foregroundColor: onColor,
                  ),
                  child: Text(
                    _saving ? s.saving : s.save,
                    style:
                        theme.textTheme.titleMedium?.copyWith(color: onColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 星期圓形按鈕
class _DayButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  const _DayButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            curve: Motion.enter,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? color
                  : scheme.onSurface.withValues(alpha: 0.06),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? onColor : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
