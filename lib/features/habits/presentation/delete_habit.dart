import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/habit.dart';
import 'habit_providers.dart';

/// 刪除前確認,刪除後提供「復原」
Future<void> confirmDeleteHabit(
    BuildContext context, WidgetRef ref, Habit habit) async {
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(todayProvider.notifier);

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('永久刪除'),
      content: Text('確定要刪除「${habit.name}」嗎?所有打卡紀錄也會一併刪除。'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除')),
      ],
    ),
  );
  if (ok != true) return;

  final snap = await notifier.deleteWithSnapshot(habit.id!);
  if (snap == null) return;

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('已刪除「${habit.name}」'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: '復原',
          onPressed: () => notifier.restoreDeleted(snap),
        ),
      ),
    );
}
