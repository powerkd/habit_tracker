import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/glass_kit.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late String _iconKey;
  late int _colorValue;
  late int _weekdays;
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
    if (_weekdays == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('至少選擇一天')));
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
        ));
      } else {
        await notifier.add(
          name: _name.text,
          description: _desc.text,
          iconKey: _iconKey,
          colorValue: _colorValue,
          remindTime: _remindTime,
          weekdays: _weekdays,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('儲存失敗：$e')));
    }
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );

  Widget _section(String title, Widget child) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(_colorValue);
    final onColor =
        color.computeLuminance() > 0.6 ? Colors.black87 : Colors.white;

    return GlassScaffold(
      appBar: AppBar(title: Text(_isEdit ? '編輯習慣' : '新增習慣')),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _section(
              '基本資料',
              Column(
                children: [
                  TextFormField(
                    controller: _name,
                    maxLength: 30,
                    focusNode: _nameFocus,
                    decoration: _dec('習慣名稱', hint: '例如：閱讀 15 分鐘'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? '請輸入習慣名稱'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _desc,
                    maxLength: 100,
                    maxLines: 2,
                    decoration: _dec('說明（選填）'),
                  ),
                ],
              ),
            ),
            _section(
              '外觀',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('圖示', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
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
                            HapticFeedback.selectionClick();
                            setState(() => _iconKey = e.key);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('顏色', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in habitColors)
                        Semantics(
                          button: true,
                          selected: _colorValue == c,
                          label: '顏色',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _colorValue = c);
                            },
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
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
                                          color: Color(c)
                                                      .computeLuminance() >
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
            _section(
              '重複與提醒',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('重複', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: _DayButton(
                            label: weekdayNames[i],
                            selected: (_weekdays >> i) & 1 == 1,
                            color: color,
                            onColor: onColor,
                            onTap: () {
                              HapticFeedback.selectionClick();
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('每天'),
                        selected: _weekdays == allWeekdays,
                        onSelected: (_) =>
                            setState(() => _weekdays = allWeekdays),
                      ),
                      ChoiceChip(
                        label: const Text('平日'),
                        selected: _weekdays == workdays,
                        onSelected: (_) =>
                            setState(() => _weekdays = workdays),
                      ),
                      ChoiceChip(
                        label: const Text('週末'),
                        selected: _weekdays == weekend,
                        onSelected: (_) =>
                            setState(() => _weekdays = weekend),
                      ),
                    ],
                  ),
                  if (_weekdays == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '至少選擇一天',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text('提醒', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alarm),
                    title: Text(_remindTime ?? '未設定'),
                    subtitle: const Text('點一下選擇時間'),
                    onTap: _pickTime,
                    trailing: _remindTime == null
                        ? null
                        : IconButton(
                            tooltip: '清除提醒',
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _remindTime = null),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: onColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  _saving ? '儲存中…' : '儲存',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: onColor),
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
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? color
                  : scheme.onSurface.withValues(alpha: 0.06),
            ),
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
    );
  }
}