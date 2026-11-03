import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/glass_kit.dart';
import '../habits/presentation/habit_providers.dart';
import 'archived_page.dart';
import 'backup_service.dart';
import 'settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await BackupService().export();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Habit Tracker 備份',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('匯出失敗:$e')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('匯入備份'),
        content: const Text('這會取代目前所有習慣與打卡紀錄,確定要繼續嗎?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('選擇檔案')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file == null) return; // 使用者取消

      final bytes = await file.readAsBytes();

      final r = await BackupService().importJson(utf8.decode(bytes));
      await ref.read(todayProvider.notifier).refresh(); // 重新載入並重排提醒
      messenger.showSnackBar(SnackBar(
          content: Text('匯入完成:${r.habits} 個習慣、${r.logs} 筆打卡紀錄')));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('匯入失敗:${e.message}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('匯入失敗:$e')));
    }
  }

  Widget _section(BuildContext context, String title, Widget child) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
            padding: const EdgeInsets.all(8),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return GlassScaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _section(
            context,
            '外觀',
            Padding(
              padding: const EdgeInsets.all(8),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('系統')),
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('淺色')),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('深色')),
                ],
                selected: {mode},
                onSelectionChanged: (s) =>
                    ref.read(themeModeProvider.notifier).setMode(s.first),
              ),
            ),
          ),
          _section(
            context,
            '資料',
            Column(
              children: [
                _SettingsTile(
                  icon: Icons.archive_outlined,
                  title: '已封存的習慣',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ArchivedPage()),
                  ),
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.upload_file_outlined,
                  title: '匯出備份',
                  subtitle: '存成 JSON 檔,可傳到雲端或其他手機',
                  onTap: () => _export(context),
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: '匯入備份',
                  subtitle: '從 JSON 檔還原(會取代目前資料)',
                  onTap: () => _import(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 8,
      thickness: 0.5,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: scheme.primary, size: 22),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      onTap: onTap,
    );
  }
}