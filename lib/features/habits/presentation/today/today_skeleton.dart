import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/motion.dart';
import '../../../../core/tokens.dart';

/// 載入中的骨架畫面。
/// 延遲約 150 ms 才淡入,資料很快回來時使用者不會看到閃一下。
class TodaySkeleton extends StatefulWidget {
  const TodaySkeleton({super.key});

  @override
  State<TodaySkeleton> createState() => _TodaySkeletonState();
}

class _TodaySkeletonState extends State<TodaySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Timer? _delay;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _delay = Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = IosColors.of(context).card;
    final hi = Color.alphaBlend(
      (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
      base,
    );

    return AnimatedOpacity(
      opacity: _show ? 1 : 0,
      duration: Motion.of(context, Motion.normal),
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final color = Color.lerp(base, hi, _pulse.value)!;

              Widget block(double h, {double? w, double radius = 8}) =>
                  Container(
                    width: w,
                    height: h,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(radius),
                    ),
                  );

              return ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  block(14, w: 120, radius: 7),
                  const SizedBox(height: 10),
                  block(34, w: 160, radius: 10),
                  const SizedBox(height: 16),
                  block(84, radius: Radii.card),
                  const SizedBox(height: 20),
                  for (var i = 0; i < 4; i++) ...[
                    block(72, radius: Radii.card),
                    const SizedBox(height: Gap.md),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
