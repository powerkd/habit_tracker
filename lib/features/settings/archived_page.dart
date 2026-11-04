import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/glass_kit.dart';
import '../../core/strings.dart';
import '../habits/domain/habit.dart';
import '../habits/domain/habit_style.dart';
import '../habits/presentation/habit_providers.dart';

class ArchivedPage extends ConsumerWidget {
  const ArchivedPage({super.key});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Habit habit) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(todayProvider.notifier);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.permDelete),
        content: Text(s.permDeleteBody(habit.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
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
            content: Text(s.deleted(habit.name)),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: s.undo,
              onPressed: () async {
                try {
                  await notifier.restoreDeleted(snap);
                } catch (e) {
                  messenger.showSnackBar(
                      SnackBar(content: Text(s.restoreFailed(e))));
                }
              },
            ),
          ),
        );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.deleteFailed(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final async = ref.watch(archivedProvider);

    return GlassScaffold(
      appBar: AppBar(title: Text(s.archived)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.loadFailed(e))),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(s.noArchived));
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
                  subtitle: Text(s.startedOn(h.startDate)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: s.restore,
                        icon: const Icon(Icons.unarchive_outlined),
                        onPressed: () => ref
                            .read(todayProvider.notifier)
                            .restore(h.id!),
                      ),
                      IconButton(
                        tooltip: s.permDelete,
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
