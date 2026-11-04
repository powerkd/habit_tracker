import 'package:flutter/material.dart';

const Map<String, IconData> habitIcons = {
  'book': Icons.menu_book,
  'run': Icons.directions_run,
  'water': Icons.local_drink,
  'sleep': Icons.bedtime,
  'fitness': Icons.fitness_center,
  'meditate': Icons.self_improvement,
  'write': Icons.edit,
  'music': Icons.music_note,
  'food': Icons.restaurant,
  'study': Icons.school,
};

/// 新增習慣可選的顏色:iOS 系統色
const List<int> habitColors = [
  0xFF007AFF, // blue
  0xFF30B0C7, // teal
  0xFF34C759, // green
  0xFFFF9500, // orange
  0xFFFF3B30, // red
  0xFFFF2D55, // pink
  0xFFAF52DE, // purple
  0xFF5856D6, // indigo
];

/// 舊版色盤。只用來讓舊習慣繼續正常顯示,不再提供選擇。
const List<int> legacyHabitColors = [
  0xFF4CAF50,
  0xFF2196F3,
  0xFFFF9800,
  0xFFE91E63,
  0xFF9C27B0,
  0xFF009688,
  0xFFF44336,
  0xFF795548,
];

/// 編輯頁用:色盤 + 目前習慣的顏色(若是舊色就補在最前面,才看得到選取狀態)
List<int> habitColorChoices(int? current) {
  if (current == null || habitColors.contains(current)) return habitColors;
  return [current, ...habitColors];
}

IconData iconFor(String key) =>
    habitIcons[key] ?? Icons.check_circle_outline;
