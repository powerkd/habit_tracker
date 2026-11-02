import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('外觀', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
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
          const SizedBox(height: 24),
          Text('資料', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.archive_outlined),
            title: const Text('已封存的習慣'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArchivedPage()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('匯出備份'),
            subtitle: const Text('存成 JSON 檔,可傳到雲端或其他手機'),
            onTap: () => _export(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download_outlined),
            title: const Text('匯入備份'),
            subtitle: const Text('從 JSON 檔還原(會取代目前資料)'),
            onTap: () => _import(context, ref),
          ),
        ],
      ),
    );
  }
}
