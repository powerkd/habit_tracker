import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/glass_kit.dart';
import '../../core/haptics.dart';
import '../../core/strings.dart';
import '../../core/toast.dart';
import '../../core/tokens.dart';
import '../habits/domain/habit.dart';
import '../habits/domain/habit_style.dart';
import '../habits/presentation/habit_providers.dart';

class ArchivedPage extends ConsumerWidget {
  const ArchivedPage({super.key});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Habit habit) async {
    final s = S.of(context);
    // await 之前先取得,之後不必再用 BuildContext
    final overlay = Overlay.of(context, rootOverlay: true);
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

      Haptics.medium();
      Toast.showOn(
        overlay,
        message: s.deleted(habit.name),
        icon: Icons.delete_outline_rounded,
        iconColor: Tone.danger,
        actionLabel: s.undo,
        duration: const Duration(seconds: 6),
        onAction: () async {
          try {
            await notifier.restoreDeleted(snap);
          } catch (e) {
            Toast.showOn(
              overlay,
              message: s.restoreFailed(e),
              icon: Icons.error_outline_rounded,
              iconColor: Tone.danger,
            );
          }
        },
      );
    } catch (e) {
      Toast.showOn(
        overlay,
        message: s.deleteFailed(e),
        icon: Icons.error_outline_rounded,
        iconColor: Tone.danger,
      );
    }
  }

  Widget _row(BuildContext context, WidgetRef ref, Habit h) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final c = IosColors.of(context);
    final color = Color(h.colorValue);
    return Padding(
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
                    color: c.labelSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.restore,
            color: theme.colorScheme.primary,
            icon: const Icon(Icons.unarchive_outlined),
            onPressed: () {
              Haptics.light();
              ref.read(todayProvider.notifier).restore(h.id!);
            },
          ),
          IconButton(
            tooltip: s.permDelete,
            color: Tone.danger,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, h),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final c = IosColors.of(context);
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
                    color: c.labelTertiary,
                  ),
                  const SizedBox(height: Gap.lg),
                  Text(s.noArchived, style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(top: Gap.sm, bottom: 40),
            children: [
              GroupedCard(
                children: [
                  for (final h in list)
                    KeyedSubtree(
                      key: ValueKey(h.id),
                      child: _row(context, ref, h),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
