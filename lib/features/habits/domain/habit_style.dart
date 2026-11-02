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

const List<int> habitColors = [
  0xFF4CAF50,
  0xFF2196F3,
  0xFFFF9800,
  0xFFE91E63,
  0xFF9C27B0,
  0xFF009688,
  0xFFF44336,
  0xFF795548,
];

IconData iconFor(String key) =>
    habitIcons[key] ?? Icons.check_circle_outline;
