import 'package:flutter/material.dart';
import 'motion.dart';

/// 數字變動時,舊值向上滑出、新值從下方滑入。
/// 數字變大往上滾,變小往下滾,方向本身就在告訴使用者增減。
class RollingNumber extends StatefulWidget {
  final int value;
  final TextStyle? style;
  const RollingNumber({super.key, required this.value, this.style});

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  int _prev = 0;

  @override
  void initState() {
    super.initState();
    _prev = widget.value;
  }

  @override
  void didUpdateWidget(RollingNumber old) {
    super.didUpdateWidget(old);
    _prev = old.value;
  }

  @override
  Widget build(BuildContext context) {
    final up = widget.value >= _prev;
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.normal),
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      transitionBuilder: (child, anim) {
        final isNew = child.key == ValueKey(widget.value);
        // 新值:從下(或上)滑入;舊值:反向滑出
        final begin = Offset(0, isNew == up ? 0.6 : -0.6);
        return ClipRect(
          child: FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: begin, end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
        );
      },
      child: Text(
        '${widget.value}',
        key: ValueKey(widget.value),
        style: widget.style,
      ),
    );
  }
}
