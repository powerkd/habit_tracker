import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/check_button.dart';
import '../../../../core/haptics.dart';
import '../../../../core/motion.dart';
import '../../../../core/routes.dart';
import '../../../../core/strings.dart';
import '../../../../core/swap_text.dart';
import '../../../../core/tokens.dart';
import '../../domain/habit_style.dart';
import '../habit_detail_page.dart';
import '../habit_providers.dart';
import 'streak_badge.dart';

/// 拖曳排序時,被拖起卡片的外觀:輕微放大 + 陰影隨進度淡入。
/// 卡片底部有 [Gap.md] 的間距,陰影要排除這一段。
Widget habitDragDecorator(Widget child, int index, Animation<double> anim) {
  return AnimatedBuilder(
    animation: anim,
    builder: (ctx, c) {
      final t = Motion.enter.transform(anim.value);
      return Transform.scale(
        scale: 1 + 0.03 * t,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              bottom: Gap.md,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.card),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45 * t),
                      blurRadius: 24 * t,
                      offset: Offset(0, 8 * t),
                    ),
                  ],
                ),
              ),
            ),
            Material(type: MaterialType.transparency, child: c),
          ],
        ),
      );
    },
    child: child,
  );
}

class HabitCard extends ConsumerStatefulWidget {
  final HabitItem item;
  final bool resting;
  const HabitCard({super.key, required this.item, this.resting = false});

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard> {
  bool _down = false;

  void _setDown(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  void _openDetail(Color color) {
    final item = widget.item;
    Navigator.push(
      context,
      appRoute(
        HabitDetailPage(
          habitId: item.habit.id!,
          previewIconKey: item.habit.iconKey,
          previewColor: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final item = widget.item;
    final resting = widget.resting;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final color = Color(item.habit.colorValue);
    final done = item.doneToday;

    final target = item.habit.dailyTarget;
    final multi = target > 1;

    final titleColor = resting
        ? scheme.onSurface.withValues(alpha: 0.5)
        : (done
            ? scheme.onSurface.withValues(alpha: 0.55)
            : scheme.onSurface);
    final subColor =
        scheme.onSurfaceVariant.withValues(alpha: resting ? 0.6 : 1.0);
    final subStyle =
        theme.textTheme.bodyMedium?.copyWith(color: subColor, fontSize: 13);
    final status = resting
        ? s.restToday
        : done
            ? s.completed
            : multi
                ? '${item.todayCount}/$target'
                : s.notDone;

    // A1:按下時卡片亮一階
    final base = IosColors.of(context).card;
    final cardColor = _down
        ? Color.alphaBlend(
            (dark ? Colors.white : Colors.black)
                .withValues(alpha: dark ? 0.08 : 0.06),
            base,
          )
        : base;

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setDown(true),
        onTapUp: (_) => _setDown(false),
        onTapCancel: () => _setDown(false),
        onTap: () => _openDetail(color),
        child: Semantics(
          button: true,
          child: AnimatedScale(
            scale: _down ? 0.98 : 1,
            duration: Motion.of(context, Motion.fast),
            curve: Motion.enter,
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.fast),
              curve: Motion.enter,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                children: [
                  Hero(
                    tag: 'habit_icon_${item.habit.id}',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: resting ? 0.08 : 0.18),
                        borderRadius: BorderRadius.circular(Radii.tile),
                      ),
                      child: Icon(
                        iconFor(item.habit.iconKey),
                        color:
                            resting ? color.withValues(alpha: 0.5) : color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StrikeTitle(
                          text: item.habit.name,
                          style: (theme.textTheme.titleMedium ??
                                  const TextStyle())
                              .copyWith(color: titleColor),
                          strike: done && !resting,
                          lineColor: titleColor,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // D2:火焰 + 連續天數
                            Flexible(
                              child: StreakBadge(
                                days: item.currentStreak,
                                label: s.streak(item.currentStreak),
                                style: subStyle,
                                dim: resting,
                              ),
                            ),
                            Text(' · ', style: subStyle),
                            SwapText(text: status, style: subStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (multi)
                    _CounterButtons(
                      item: item,
                      color: color,
                      resting: resting,
                    )
                  else
                    _ToggleButton(
                      item: item,
                      color: color,
                      resting: resting,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 標題:顏色漸變,[strike] 為 true 時從左到右畫出一條刪除線。
class _StrikeTitle extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool strike;
  final Color lineColor;

  const _StrikeTitle({
    required this.text,
    required this.style,
    required this.strike,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final dir = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, c) {
        // 量出單行文字實際寬度,刪除線才不會畫到空白處
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          ellipsis: '…',
          textDirection: dir,
          textScaler: scaler,
        )..layout(maxWidth: c.maxWidth);
        final width = tp.width;
        tp.dispose();

        return TweenAnimationBuilder<double>(
          tween: Tween(end: strike ? 1.0 : 0.0),
          duration: Motion.of(context, Motion.normal),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) => CustomPaint(
            foregroundPainter: _StrikePainter(
              progress: v.clamp(0.0, 1.0),
              textWidth: width,
              color: lineColor,
            ),
            child: child,
          ),
          child: AnimatedDefaultTextStyle(
            duration: Motion.of(context, Motion.normal),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: Text(text),
          ),
        );
      },
    );
  }
}

class _StrikePainter extends CustomPainter {
  final double progress;
  final double textWidth;
  final Color color;

  _StrikePainter({
    required this.progress,
    required this.textWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final y = size.height * 0.55;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, y), Offset(textWidth * progress, y), paint);
  }

  @override
  bool shouldRepaint(covariant _StrikePainter old) =>
      old.progress != progress ||
      old.textWidth != textWidth ||
      old.color != color;
}

/// 單次習慣:自訂打卡按鈕(填色擴張 + 勾選回彈,可中斷)
class _ToggleButton extends ConsumerWidget {
  final HabitItem item;
  final Color color;
  final bool resting;
  const _ToggleButton({
    required this.item,
    required this.color,
    required this.resting,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final done = item.doneToday;
    return CheckButton(
      checked: done,
      size: 30,
      color: resting ? color.withValues(alpha: 0.5) : color,
      semanticLabel: done ? s.uncheck : s.check,
      onTap: () => ref
          .read(todayProvider.notifier)
          .toggle(item.habit.id!, item.doneToday),
    );
  }
}

/// 多次習慣:− 按鈕 + 進度環 + 按鈕。達到目標時進度環彈一下。
class _CounterButtons extends ConsumerWidget {
  final HabitItem item;
  final Color color;
  final bool resting;
  const _CounterButtons({
    required this.item,
    required this.color,
    required this.resting,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final target = item.habit.dailyTarget;
    final count = item.todayCount;
    final done = item.doneToday;
    final ringColor = resting ? color.withValues(alpha: 0.5) : color;
    final fast = Motion.of(context, Motion.fast);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (count > 0)
          SizedBox(
            width: 40,
            height: 48,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: s.decrease,
              icon: const Icon(Icons.remove_circle_outline, size: 24),
              onPressed: () {
                Haptics.light();
                ref.read(todayProvider.notifier).decrement(item.habit.id!);
              },
            ),
          ),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            tooltip: done ? s.targetReached : s.tapOnce(count, target),
            onPressed: done
                ? null
                : () {
                    if (count + 1 >= target) {
                      Haptics.medium();
                    } else {
                      Haptics.light();
                    }
                    ref
                        .read(todayProvider.notifier)
                        .increment(item.habit.id!);
                  },
            icon: _Pulse(
              trigger: done,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: (count / target).clamp(0.0, 1.0)),
                      duration: Motion.of(context, Motion.normal),
                      curve: Motion.enter,
                      builder: (context, v, _) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 3.5,
                        backgroundColor:
                            scheme.outline.withValues(alpha: 0.25),
                        color: ringColor,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: fast,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.add,
                      key: ValueKey(done),
                      size: 18,
                      color: ringColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// [trigger] 從 false 變 true 時,子元件放大再回彈一次。
/// 系統開啟「減少動態效果」時不播放。
class _Pulse extends StatefulWidget {
  final bool trigger;
  final Widget child;
  const _Pulse({required this.trigger, required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.28)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.28, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 65,
    ),
  ]).animate(_c);

  @override
  void didUpdateWidget(covariant _Pulse old) {
    super.didUpdateWidget(old);
    if (!old.trigger &&
        widget.trigger &&
        !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
