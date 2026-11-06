import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/motion.dart';
import '../../../../core/progress_ring.dart';
import '../../../../core/strings.dart';
import '../../../../core/swap_text.dart';
import '../../../../core/tokens.dart';

/// 日期、大標題、今日進度卡
class TodayHeader extends StatelessWidget {
  final int scheduledCount;
  final int done;
  const TodayHeader({
    super.key,
    required this.scheduledCount,
    required this.done,
  });

  String _dateText(BuildContext context) => DateFormat.yMMMd(
        Localizations.localeOf(context).toString(),
      ).format(DateTime.now());

  /// 子元件更換時淡入淡出,並靠左對齊
  Widget _fade(BuildContext context, Widget child,
      {Alignment alignment = Alignment.centerLeft}) {
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.normal),
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final empty = scheduledCount == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateText(context),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          _fade(
            context,
            Text(
              empty ? s.restToday : s.today,
              key: ValueKey(empty),
              style: theme.textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: 16),
          // 進度卡與「今天沒有排程」互換時,高度平滑變化
          AnimatedSize(
            duration: Motion.of(context, Motion.normal),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _fade(
              context,
              empty
                  ? Text(
                      s.noScheduled,
                      key: const ValueKey('none'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : _ProgressCard(
                      key: const ValueKey('card'),
                      scheduledCount: scheduledCount,
                      done: done,
                    ),
              alignment: Alignment.topLeft,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int scheduledCount;
  final int done;
  const _ProgressCard({
    super.key,
    required this.scheduledCount,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: s.progressLabel(done, scheduledCount),
        excludeSemantics: true,
        child: Container(
          decoration: BoxDecoration(
            color: IosColors.of(context).card,
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: done / scheduledCount),
                duration: Motion.of(context, Motion.slow),
                curve: Motion.enter,
                builder: (context, v, _) => ProgressRing(
                  progress: v,
                  child: Text(
                    '${(v * 100).round()}%',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // B2:文字改變時滑動淡入
                    SwapText(
                      text: s.doneOf(done, scheduledCount),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    SwapText(
                      text: done == scheduledCount
                          ? s.allDoneEmoji
                          : s.remaining(scheduledCount - done),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
