import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/swap_text.dart';
import '../../domain/today_logic.dart';

/// 連續天數:火焰圖示 + 文字。
/// - 依天數分四級,顏色與光暈逐級加強。
/// - 天數增加時火焰跳一下並擺動;升級時跳得更大。
/// - 0 天時不顯示火焰。
class StreakBadge extends StatefulWidget {
  final int days;

  /// 已經本地化的文字,例如 s.streak(days)
  final String label;
  final TextStyle? style;
  final bool dim;

  const StreakBadge({
    super.key,
    required this.days,
    required this.label,
    required this.style,
    this.dim = false,
  });

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  double _amp = 0.4;

  static const _colors = [
    Colors.transparent,
    Color(0xFFFF9500), // 1~6
    Color(0xFFFF6B1A), // 7~29
    Color(0xFFFFC107), // 30~99
    Color(0xFFFF2D7A), // 100+
  ];
  static const _glow = [0.0, 0.0, 8.0, 12.0, 16.0];
  static const _size = [0.0, 14.0, 15.0, 16.0, 17.0];

  @override
  void didUpdateWidget(covariant StreakBadge old) {
    super.didUpdateWidget(old);
    if (widget.days > old.days &&
        !MediaQuery.disableAnimationsOf(context)) {
      _amp = streakTier(widget.days) > streakTier(old.days) ? 0.9 : 0.4;
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
    final tier = streakTier(widget.days);
    final style = widget.style;

    if (tier == 0) {
      return SwapText(text: widget.label, style: style);
    }

    final base = _colors[tier];
    final color = widget.dim ? base.withValues(alpha: 0.5) : base;
    final glow = widget.dim ? 0.0 : _glow[tier];
    final size = _size[tier];

    final flame = AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final k = _c.value;
        final scale = 1 + _amp * math.sin(k * math.pi);
        final tilt = math.sin(k * math.pi * 3) * 0.25 * (1 - k);
        return Transform.rotate(
          angle: tilt,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: size + 2,
        height: size + 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (glow > 0)
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.55),
                      blurRadius: glow,
                    ),
                  ],
                ),
                child: const SizedBox(width: 6, height: 6),
              ),
            Icon(Icons.local_fire_department_rounded,
                size: size, color: color),
          ],
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        flame,
        const SizedBox(width: 3),
        Flexible(
          child: SwapText(
            text: widget.label,
            style: tier >= 2
                ? style?.copyWith(fontWeight: FontWeight.w600)
                : style,
          ),
        ),
      ],
    );
  }
}
