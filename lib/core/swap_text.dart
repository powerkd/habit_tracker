import 'package:flutter/material.dart';
import 'motion.dart';

/// 文字改變時,舊字下沉淡出、新字從下方淡入。
/// 系統開啟「減少動態效果」時,[Motion.of] 會讓動畫時間縮為 0。
class SwapText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Alignment alignment;

  const SwapText({
    super.key,
    required this.text,
    this.style,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.normal),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [...previous, ?current],
      ),
      child: Text(
        text,
        key: ValueKey(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
