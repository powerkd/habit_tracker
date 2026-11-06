import 'package:flutter/material.dart';
import '../../../../core/strings.dart';

/// 還沒有任何習慣時的空狀態
class TodayEmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const TodayEmptyView({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rounded,
                size: 72,
                color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(s.noHabits, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              s.noHabitsSub,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(s.addFirst),
            ),
          ],
        ),
      ),
    );
  }
}
