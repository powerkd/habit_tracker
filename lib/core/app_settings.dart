import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'haptics.dart';
import 'locale_provider.dart' show prefsProvider;

/// 主題色選項(淺色 / 深色各一個值)
class AccentChoice {
  final String name;
  final Color light;
  final Color dark;
  const AccentChoice(this.name, this.light, this.dark);
}

const kAccentChoices = <AccentChoice>[
  AccentChoice('Blue', Color(0xFF007AFF), Color(0xFF0A84FF)),
  AccentChoice('Teal', Color(0xFF30B0C7), Color(0xFF40C8E0)),
  AccentChoice('Green', Color(0xFF34C759), Color(0xFF30D158)),
  AccentChoice('Orange', Color(0xFFFF9500), Color(0xFFFF9F0A)),
  AccentChoice('Red', Color(0xFFFF3B30), Color(0xFFFF453A)),
  AccentChoice('Pink', Color(0xFFFF2D55), Color(0xFFFF375F)),
  AccentChoice('Purple', Color(0xFFAF52DE), Color(0xFFBF5AF2)),
  AccentChoice('Indigo', Color(0xFF5856D6), Color(0xFF5E5CE6)),
];

class AppSettings {
  final bool haptics;
  final bool celebrate;
  final bool milestones;
  final bool mondayStart;
  final bool showRest;
  final int accent;

  const AppSettings({
    this.haptics = true,
    this.celebrate = true,
    this.milestones = true,
    this.mondayStart = true,
    this.showRest = true,
    this.accent = 0,
  });

  AppSettings copyWith({
    bool? haptics,
    bool? celebrate,
    bool? milestones,
    bool? mondayStart,
    bool? showRest,
    int? accent,
  }) =>
      AppSettings(
        haptics: haptics ?? this.haptics,
        celebrate: celebrate ?? this.celebrate,
        milestones: milestones ?? this.milestones,
        mondayStart: mondayStart ?? this.mondayStart,
        showRest: showRest ?? this.showRest,
        accent: accent ?? this.accent,
      );

  AccentChoice get accentChoice =>
      kAccentChoices[accent.clamp(0, kAccentChoices.length - 1)];
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _kHaptics = 'pref_haptics';
  static const _kCelebrate = 'pref_celebrate';
  static const _kMilestones = 'pref_milestones';
  static const _kMonday = 'pref_monday_start';
  static const _kShowRest = 'pref_show_rest';
  static const _kAccent = 'pref_accent';

  @override
  AppSettings build() {
    final p = ref.read(prefsProvider);
    final s = AppSettings(
      haptics: p.getBool(_kHaptics) ?? true,
      celebrate: p.getBool(_kCelebrate) ?? true,
      milestones: p.getBool(_kMilestones) ?? true,
      mondayStart: p.getBool(_kMonday) ?? true,
      showRest: p.getBool(_kShowRest) ?? true,
      accent: p.getInt(_kAccent) ?? 0,
    );
    Haptics.enabled = s.haptics;
    return s;
  }

  Future<void> setHaptics(bool v) async {
    Haptics.enabled = v;
    state = state.copyWith(haptics: v);
    await ref.read(prefsProvider).setBool(_kHaptics, v);
  }

  Future<void> setCelebrate(bool v) async {
    state = state.copyWith(celebrate: v);
    await ref.read(prefsProvider).setBool(_kCelebrate, v);
  }

  Future<void> setMilestones(bool v) async {
    state = state.copyWith(milestones: v);
    await ref.read(prefsProvider).setBool(_kMilestones, v);
  }

  Future<void> setMondayStart(bool v) async {
    state = state.copyWith(mondayStart: v);
    await ref.read(prefsProvider).setBool(_kMonday, v);
  }

  Future<void> setShowRest(bool v) async {
    state = state.copyWith(showRest: v);
    await ref.read(prefsProvider).setBool(_kShowRest, v);
  }

  Future<void> setAccent(int i) async {
    state = state.copyWith(accent: i);
    await ref.read(prefsProvider).setInt(_kAccent, i);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
        AppSettingsNotifier.new);
