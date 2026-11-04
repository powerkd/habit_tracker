import 'package:flutter/material.dart';

/// 全 App 共用的動畫時長與曲線。
class Motion {
  Motion._();

  // 時長
  static const fast = Duration(milliseconds: 150); // 按鈕、勾選
  static const normal = Duration(milliseconds: 250); // 卡片、列表
  static const slow = Duration(milliseconds: 400); // 頁面轉場、圖表

  // 曲線
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const emphasize = Curves.easeOutBack;

  /// 使用者開啟「減少動態效果」時回傳 true。
  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;

  /// 依系統設定縮短動畫:減少動態時直接變成 0。
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
