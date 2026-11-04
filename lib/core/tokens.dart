import 'package:flutter/material.dart';

/// 圓角:全 App 只用這四種
class Radii {
  Radii._();
  static const tile = 14.0; // 圖示底塊
  static const control = 16.0; // 輸入框、小元件
  static const card = 24.0; // 清單卡片、統計卡
  static const panel = 28.0; // 大面板、彈窗、膠囊按鈕
}

/// 間距:4 的倍數
class Gap {
  Gap._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// 語意色(iOS 系統色)。fire=橘、trophy=黃、danger=紅
class Tone {
  Tone._();
  static const fire = Color(0xFFFF9500);
  static const trophy = Color(0xFFFFCC00);
  static const danger = Color(0xFFFF3B30);
}

/// iOS 表面與文字色。用法:IosColors.of(context).card
class IosColors {
  const IosColors._(this.isDark);
  final bool isDark;

  factory IosColors.of(BuildContext context) =>
      IosColors._(Theme.of(context).brightness == Brightness.dark);

  Color _p(Color light, Color dark) => isDark ? dark : light;

  Color get background =>
      _p(const Color(0xFFF2F2F7), const Color(0xFF000000));
  Color get card => _p(const Color(0xFFFFFFFF), const Color(0xFF1C1C1E));
  Color get cardElevated =>
      _p(const Color(0xFFFFFFFF), const Color(0xFF2C2C2E));

  Color get label => _p(const Color(0xFF000000), const Color(0xFFFFFFFF));
  Color get labelSecondary =>
      _p(const Color(0x993C3C43), const Color(0x99EBEBF5));
  Color get labelTertiary =>
      _p(const Color(0x4D3C3C43), const Color(0x4DEBEBF5));
  Color get separator =>
      _p(const Color(0x4A3C3C43), const Color(0x99545458));

  Color get success => _p(const Color(0xFF34C759), const Color(0xFF30D158));
}
