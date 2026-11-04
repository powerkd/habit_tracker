import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 在 main 裡用 overrideWithValue 注入
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider 需要在 main 注入'),
);

const kZh = Locale('zh', 'TW');
const kEn = Locale('en');

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'locale';

  @override
  Locale build() {
    final saved = ref.read(prefsProvider).getString(_key);
    if (saved == 'en') return kEn;
    if (saved == 'zh') return kZh;
    // 第一次啟動：系統是中文就用中文，其他用英文
    return PlatformDispatcher.instance.locale.languageCode == 'zh' ? kZh : kEn;
  }

  Future<void> set(Locale l) async {
    state = l;
    await ref
        .read(prefsProvider)
        .setString(_key, l.languageCode == 'zh' ? 'zh' : 'en');
  }
}
