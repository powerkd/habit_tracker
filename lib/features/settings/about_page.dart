import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/glass_kit.dart';
import '../../core/links.dart';
import '../../core/settings_strings.dart';
import '../../core/strings.dart';
import '../../core/tokens.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = IosColors.of(context);
    final accent = Theme.of(context).colorScheme.primary;

    return GlassScaffold(
      appBar: AppBar(title: Text(s.aboutPageTitle)),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snap) {
          final info = snap.data;
          final version =
              info == null ? '—' : '${info.version} (${info.buildNumber})';

          return ListView(
            padding: const EdgeInsets.only(top: Gap.xl, bottom: 40),
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Radii.card),
                  ),
                  child: Icon(Icons.checklist_rounded,
                      size: 44, color: accent),
                ),
              ),
              const SizedBox(height: Gap.md),
              Center(
                child: Text(
                  info?.appName ?? '',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 8, 40, 0),
                child: Text(
                  s.aboutBlurb,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, height: 1.4, color: c.labelSecondary),
                ),
              ),
              const SizedBox(height: Gap.xl),
              GroupedCard(children: [
                GroupedRow(
                  title: s.versionLabel,
                  trailing: Text(
                    version,
                    style: TextStyle(fontSize: 17, color: c.labelSecondary),
                  ),
                ),
                GroupedRow(
                  icon: Icons.code_rounded,
                  title: s.sourceCodeRow,
                  subtitle: 'github.com/powerkd/habit_tracker',
                  trailing:
                      Icon(Icons.open_in_new, size: 20, color: c.labelTertiary),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await openUrl(kRepoUrl);
                    if (!ok) {
                      messenger.showSnackBar(
                          SnackBar(content: Text(s.openLinkFailed)));
                    }
                  },
                ),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
                child: Text(
                  s.dataNote,
                  style: TextStyle(fontSize: 13, color: c.labelSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
