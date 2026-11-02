import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('沒有儲存過時預設跟隨系統', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final mode = await container.read(themeModeProvider.future);
    expect(mode, ThemeMode.system);
  });

  test('設定深色後會被儲存並可讀回', () async {
    SharedPreferences.setMockInitialValues({});
    final c1 = ProviderContainer();
    await c1.read(themeModeProvider.future);
    await c1.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    c1.dispose();

    // 模擬重新開啟 App
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final mode = await c2.read(themeModeProvider.future);
    expect(mode, ThemeMode.dark);
  });
}
