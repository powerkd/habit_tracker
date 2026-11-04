import 'package:flutter/services.dart';

/// 全 App 的觸覺回饋入口,可由設定頁整體關閉
class Haptics {
  Haptics._();
  static bool enabled = true;

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }
}
