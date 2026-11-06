import 'package:flutter/material.dart';
import 'motion.dart';

/// 依 [visible] 展開或收合子元件(高度 + 淡入淡出)。
/// 收合完成後不會建立子元件,隱藏時也不會吃到點擊。
class Reveal extends StatelessWidget {
  final bool visible;
  final Widget child;

  const Reveal({super.key, required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: visible ? 1.0 : 0.0),
      duration: Motion.of(context, Motion.normal),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) {
        final t = v.clamp(0.0, 1.0);
        if (t == 0) return const SizedBox.shrink();
        return IgnorePointer(
          ignoring: !visible,
          child: ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: t,
              child: Opacity(opacity: t, child: child),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// 子元件第一次出現時,高度展開並淡入。
/// [animate] 為 false 時直接顯示,不播放動畫。
/// 只在 State 建立時判斷一次,之後 [animate] 變化不會重播。
class AppearOnMount extends StatefulWidget {
  final bool animate;
  final Widget child;

  const AppearOnMount({
    super.key,
    required this.animate,
    required this.child,
  });

  @override
  State<AppearOnMount> createState() => _AppearOnMountState();
}

class _AppearOnMountState extends State<AppearOnMount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.slow,
    value: widget.animate ? 0 : 1,
  );
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.animate) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curve,
      child: FadeTransition(opacity: _curve, child: widget.child),
    );
  }
}
