import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/locale_provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_settings.dart';
import '../../core/glass_kit.dart';
import '../../core/haptics.dart';
import '../../core/links.dart';
import '../../core/settings_strings.dart';
import '../../core/strings.dart';
import '../../core/tokens.dart';
import '../../core/widget_service.dart';
import '../habits/presentation/habit_providers.dart';
import 'about_page.dart';
import 'archived_page.dart';
import 'backup_service.dart';
import 'help_page.dart';
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
                backgroundColor: Tone.danger,
                foregroundColor: Colors.white,
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

  Future<void> _openIssues(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = S.of(context);
    final ok = await openUrl(kIssuesUrl);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(s.openLinkFailed)));
    }
  }

  /// 複製版本與系統資訊,不含任何習慣資料
  Future<void> _copyDiagnostics(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final info = await PackageInfo.fromPlatform();
    final text = [
      '${info.appName} ${info.version}+${info.buildNumber}',
      'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'Locale: $locale',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(SnackBar(content: Text(s.diagCopied)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final c = IosColors.of(context);
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final locale = ref.watch(localeProvider);
    final cfg = ref.watch(appSettingsProvider);
    final cfgN = ref.read(appSettingsProvider.notifier);
    final dark = theme.brightness == Brightness.dark;

    return GlassScaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        // 底部留空給浮動分頁列
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          SectionHeader(s.appearance),
          GroupedCard(children: [
            _PickerRow<ThemeMode>(
              title: s.appearance,
              value: mode,
              options: {
                ThemeMode.system: s.system,
                ThemeMode.light: s.light,
                ThemeMode.dark: s.dark,
              },
              onChanged: (v) =>
                  ref.read(themeModeProvider.notifier).setMode(v),
            ),
            _PickerRow<String>(
              title: s.language,
              value: locale.languageCode == 'zh' ? 'zh' : 'en',
              options: const {'zh': '繁體中文', 'en': 'English'},
              onChanged: (v) => ref
                  .read(localeProvider.notifier)
                  .set(v == 'zh' ? kZh : kEn),
            ),
            // 主題色
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.accentTitle, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < kAccentChoices.length; i++)
                        Semantics(
                          button: true,
                          selected: cfg.accent == i,
                          label: '${s.accentTitle} ${kAccentChoices[i].name}',
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Haptics.selection();
                              cfgN.setAccent(i);
                            },
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: dark
                                        ? kAccentChoices[i].dark
                                        : kAccentChoices[i].light,
                                  ),
                                  child: cfg.accent == i
                                      ? const Icon(Icons.check,
                                          size: 18, color: Colors.white)
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
          ]),
          SectionHeader(s.feedbackSection),
          GroupedCard(children: [
            _SwitchRow(
              icon: Icons.vibration,
              title: s.hapticsTitle,
              subtitle: s.hapticsSub,
              value: cfg.haptics,
              onChanged: cfgN.setHaptics,
            ),
            _SwitchRow(
              icon: Icons.celebration_outlined,
              title: s.celebrateTitle,
              subtitle: s.celebrateSub,
              value: cfg.celebrate,
              onChanged: cfgN.setCelebrate,
            ),
            _SwitchRow(
              icon: Icons.local_fire_department_outlined,
              title: s.milestoneTitle,
              subtitle: s.milestoneSub,
              value: cfg.milestones,
              onChanged: cfgN.setMilestones,
            ),
          ]),
          SectionHeader(s.displaySection),
          GroupedCard(children: [
            _PickerRow<bool>(
              title: s.weekStartTitle,
              value: cfg.mondayStart,
              options: {true: s.monday, false: s.sunday},
              onChanged: cfgN.setMondayStart,
            ),
            _SwitchRow(
              icon: Icons.bedtime_outlined,
              title: s.showRestTitle,
              subtitle: s.showRestSub,
              value: cfg.showRest,
              onChanged: cfgN.setShowRest,
            ),
          ]),
          if (Platform.isAndroid) ...[
            SectionHeader(s.homeScreen),
            GroupedCard(children: [
              GroupedRow(
                icon: Icons.widgets_outlined,
                title: s.addWidget,
                subtitle: s.addWidgetSub,
                onTap: () => _pinWidget(context),
              ),
            ]),
          ],
          SectionHeader(s.data),
          GroupedCard(children: [
            GroupedRow(
              icon: Icons.archive_outlined,
              title: s.archived,
              trailing: Icon(Icons.chevron_right, color: c.labelTertiary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArchivedPage()),
              ),
            ),
            GroupedRow(
              icon: Icons.upload_file_outlined,
              title: s.export,
              subtitle: s.exportSub,
              onTap: () => _export(context),
            ),
            GroupedRow(
              icon: Icons.download_outlined,
              title: s.import,
              subtitle: s.importSub,
              onTap: () => _import(context, ref),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
            child: Text(
              s.dataNote,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: c.labelSecondary, fontSize: 13),
            ),
          ),
          SectionHeader(s.helpSupportSection),
          GroupedCard(children: [
            GroupedRow(
              icon: Icons.help_outline_rounded,
              title: s.helpRowTitle,
              subtitle: s.helpRowSub,
              trailing: Icon(Icons.chevron_right, color: c.labelTertiary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpPage()),
              ),
            ),
            GroupedRow(
              icon: Icons.bug_report_outlined,
              title: s.supportRowTitle,
              subtitle: s.supportRowSub,
              trailing:
                  Icon(Icons.open_in_new, size: 20, color: c.labelTertiary),
              onTap: () => _openIssues(context),
            ),
            GroupedRow(
              icon: Icons.copy_all_outlined,
              title: s.diagRowTitle,
              subtitle: s.diagRowSub,
              onTap: () => _copyDiagnostics(context),
            ),
            GroupedRow(
              icon: Icons.info_outline_rounded,
              title: s.aboutRowTitle,
              trailing: Icon(Icons.chevron_right, color: c.labelTertiary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutPage()),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// 一列「標題 + 右側藍字數值」,點擊彈出選單
class _PickerRow<T> extends StatelessWidget {
  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _PickerRow({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      position: PopupMenuPosition.under,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final e in options.entries)
          PopupMenuItem<T>(value: e.key, child: Text(e.value)),
      ],
      child: GroupedRow(
        title: title,
        trailing: ValueLabel(options[value] ?? ''),
      ),
    );
  }
}

/// 一列「圖示 + 標題 + 開關」
class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GroupedRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}
