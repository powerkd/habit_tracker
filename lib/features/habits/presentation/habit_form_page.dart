import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/habit.dart';
import '../domain/habit_style.dart';
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
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late String _iconKey;
  late int _colorValue;
  String? _remindTime; // "HH:mm"；null 代表不提醒
  bool _saving = false;

  bool get _isEdit => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _name = TextEditingController(text: h?.name ?? '');
    _desc = TextEditingController(text: h?.description ?? '');
    _iconKey = h?.iconKey ?? 'book';
    _colorValue = h?.colorValue ?? habitColors.first;
    _remindTime = h?.remindTime;
  }

  @override
  void dispose() {
    _name.dispose();
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
        ));
      } else {
        await notifier.add(
          name: _name.text,
          description: _desc.text,
          iconKey: _iconKey,
          colorValue: _colorValue,
          remindTime: _remindTime,
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

  @override
  Widget build(BuildContext context) {
    final color = Color(_colorValue);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '編輯習慣' : '新增習慣')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              maxLength: 30,
              autofocus: !_isEdit,
              decoration: const InputDecoration(
                labelText: '習慣名稱',
                hintText: '例如：閱讀 15 分鐘',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '請輸入習慣名稱' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLength: 100,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '說明（選填）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text('圖示', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in habitIcons.entries)
                  ChoiceChip(
                    label: Icon(e.value,
                        color: _iconKey == e.key ? Colors.white : null),
                    selected: _iconKey == e.key,
                    selectedColor: color,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _iconKey = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('顏色', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in habitColors)
                  GestureDetector(
                    onTap: () => setState(() => _colorValue = c),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(c),
                      child: _colorValue == c
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('每日提醒', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: const Icon(Icons.alarm),
                title: Text(_remindTime ?? '未設定'),
                subtitle: const Text('點一下選擇時間'),
                onTap: _pickTime,
                trailing: _remindTime == null
                    ? null
                    : IconButton(
                        tooltip: '清除提醒',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _remindTime = null),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: color),
              child: Text(_saving ? '儲存中…' : '儲存'),
            ),
          ],
        ),
      ),
    );
  }
}
