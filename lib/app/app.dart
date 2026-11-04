import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/habits/presentation/today_page.dart';
import '../features/settings/settings_providers.dart';
import '../core/app_navigator.dart';
import '../core/glass_kit.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/locale_provider.dart';

class HabitApp extends ConsumerWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) => GlassBackground(child: child!),
      // 其他設定(locale、localizationsDelegates 等)保留你原本的
      home: const TodayPage(),
    );
  }
}
