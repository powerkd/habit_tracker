import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/locale_provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/glass_kit.dart';
import '../../core/strings.dart';
import '../../core/widget_service.dart';
import '../habits/presentation/habit_providers.dart';
import 'archived_page.dart';
import 'backup_service.dart';
import 'settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = S.of(context);
    try {
      final file = await BackupService().export();
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: s.backupSubject),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.exportFailed(e))));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = S.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.import),
        content: Text(s.importWarn),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.pickFile)),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final r = await BackupService().importJson(utf8.decode(bytes));
      await ref.read(todayProvider.notifier).refresh();
      messenger.showSnackBar(
          SnackBar(content: Text(s.importDone(r.habits, r.logs))));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.importFailed(e.message))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.importFailed(e))));
    }
  }

  Future<void> _pinWidget(BuildContext context) async {
    final s = S.of(context);
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (supported) {
        await HomeWidget.requestPinWidget(
          name: WidgetService.providerName,
          androidName: WidgetService.providerName,
          qualifiedAndroidName: WidgetService.qualifiedName,
        );
        return;
      }
    } catch (_) {
      // 落到下面的手動教學
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.pinTitle),
        content: Text(s.pinBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.ok)),
        ],
      ),
    );
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
    final s = S.of(context);
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final locale = ref.watch(localeProvider);

    return GlassScaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _section(
            context,
            s.appearance,
            Padding(
              padding: const EdgeInsets.all(8),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto),
                      label: Text(s.system)),
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode),
                      label: Text(s.light)),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode),
                      label: Text(s.dark)),
                ],
                selected: {mode},
                onSelectionChanged: (v) =>
                    ref.read(themeModeProvider.notifier).setMode(v.first),
              ),
            ),
          ),
          _section(
            context,
            s.language,
            Padding(
              padding: const EdgeInsets.all(8),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'zh', label: Text('繁體中文')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {locale.languageCode == 'zh' ? 'zh' : 'en'},
                onSelectionChanged: (v) => ref
                    .read(localeProvider.notifier)
                    .set(v.first == 'zh' ? kZh : kEn),
              ),
            ),
          ),
          if (Platform.isAndroid)
            _section(
              context,
              s.homeScreen,
              _SettingsTile(
                icon: Icons.widgets_outlined,
                title: s.addWidget,
                subtitle: s.addWidgetSub,
                onTap: () => _pinWidget(context),
              ),
            ),
          _section(
            context,
            s.data,
            Column(
              children: [
                _SettingsTile(
                  icon: Icons.archive_outlined,
                  title: s.archived,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ArchivedPage()),
                  ),
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.upload_file_outlined,
                  title: s.export,
                  subtitle: s.exportSub,
                  onTap: () => _export(context),
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: s.import,
                  subtitle: s.importSub,
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
