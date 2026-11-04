import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/app_navigator.dart';
import '../core/app_settings.dart';
import '../core/app_shell.dart';
import '../core/glass_kit.dart';
import '../core/locale_provider.dart';
import '../features/settings/settings_providers.dart';

class HabitApp extends ConsumerWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final accent = ref.watch(appSettingsProvider.select((s) => s.accentChoice));

    return MaterialApp(
      locale: locale,
      supportedLocales: const [kZh, kEn],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: navigatorKey,
      title: '習慣追蹤',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: AppTheme.light(accent.light),
      darkTheme: AppTheme.dark(accent.dark),
      builder: (context, child) => GlassBackground(child: child!),
      home: const AppShell(),
    );
  }
}
