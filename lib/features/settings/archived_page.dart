import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/glass_kit.dart';
import '../habits/domain/habit.dart';
import '../habits/domain/habit_style.dart';
import '../habits/presentation/habit_providers.dart';

class ArchivedPage extends ConsumerWidget {
  const ArchivedPage({super.key});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Habit habit) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(todayProvider.notifier);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('永久刪除'),
        content: Text('「${habit.name}」與所有打卡紀錄都會被刪除。\n刪除後 6 秒內可以復原。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
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
              onPressed: () async {
                try {
                  await notifier.restoreDeleted(snap);
                } catch (e) {
                  messenger.showSnackBar(
                      SnackBar(content: Text('復原失敗:$e')));
                }
              },
            ),
          ),
        );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('刪除失敗:$e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(archivedProvider);

    return GlassScaffold(
      appBar: AppBar(title: const Text('已封存的習慣')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗:$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('沒有已封存的習慣'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final h = list[i];
              final color = Color(h.colorValue);
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(iconFor(h.iconKey), color: color),
                  ),
                  title: Text(h.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('開始於 ${h.startDate}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '還原',
                        icon: const Icon(Icons.unarchive_outlined),
                        onPressed: () => ref
                            .read(todayProvider.notifier)
                            .restore(h.id!),
                      ),
                      IconButton(
                        tooltip: '永久刪除',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, ref, h),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}