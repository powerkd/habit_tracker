import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/glass_kit.dart';
import '../../core/strings.dart';
import '../../core/tokens.dart';
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
              backgroundColor: Tone.danger,
              foregroundColor: Colors.white,
            ),
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
    final theme = Theme.of(context);
    final async = ref.watch(archivedProvider);

    return GlassScaffold(
      appBar: AppBar(title: Text(s.archived)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.loadFailed(e))),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: Gap.lg),
                  Text(s.noArchived, style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: Gap.md),
            itemBuilder: (context, i) {
              final h = list[i];
              final color = Color(h.colorValue);
              return GlassContainer(
                borderRadius: BorderRadius.circular(Radii.card),
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(Radii.tile),
                      ),
                      child: Icon(iconFor(h.iconKey), color: color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.startedOn(h.startDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: s.restore,
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () =>
                          ref.read(todayProvider.notifier).restore(h.id!),
                    ),
                    IconButton(
                      tooltip: s.permDelete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, ref, h),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
