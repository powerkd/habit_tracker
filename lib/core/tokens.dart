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

/// 語意色:不再各處直接寫 Colors.xxx
class Tone {
  Tone._();
  static const fire = Color(0xFFFF9F0A);
  static const trophy = Color(0xFFFFC53D);
  static const danger = Color(0xFFFF453A);
}
