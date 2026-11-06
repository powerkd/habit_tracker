import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 一次性的彩帶噴發。自動播放,播完後畫面是空的。
/// 系統開啟「減少動態效果」時不顯示。
class ConfettiBurst extends StatefulWidget {
  final Duration duration;
  final int count;
  final List<Color> colors;

  const ConfettiBurst({
    super.key,
    this.duration = const Duration(milliseconds: 2400),
    this.count = 80,
    this.colors = defaultColors,
  });

  static const defaultColors = [
    Color(0xFFFF453A),
    Color(0xFFFF9F0A),
    Color(0xFFFFD60A),
    Color(0xFF32D74B),
    Color(0xFF0A84FF),
    Color(0xFFBF5AF2),
    Color(0xFFFF375F),
  ];

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final List<_Particle> _particles = _generate();
  bool _started = false;

  List<_Particle> _generate() {
    final rnd = math.Random();
    return List.generate(widget.count, (_) {
      // 向上的寬扇形
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 2.2;
      final speed = 0.7 + rnd.nextDouble() * 0.9; // 螢幕高度 / 秒
      return _Particle(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: widget.colors[rnd.nextInt(widget.colors.length)],
        w: 6 + rnd.nextDouble() * 6,
        h: 9 + rnd.nextDouble() * 8,
        rot0: rnd.nextDouble() * math.pi * 2,
        spin: (rnd.nextDouble() - 0.5) * 10,
        flip0: rnd.nextDouble() * math.pi * 2,
        flipSpeed: 4 + rnd.nextDouble() * 8,
        circle: rnd.nextInt(5) == 0,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              progress: _c,
              particles: _particles,
              seconds: widget.duration.inMilliseconds / 1000,
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double vx, vy;
  final Color color;
  final double w, h;
  final double rot0, spin;
  final double flip0, flipSpeed;
  final bool circle;

  const _Particle({
    required this.vx,
    required this.vy,
    required this.color,
    required this.w,
    required this.h,
    required this.rot0,
    required this.spin,
    required this.flip0,
    required this.flipSpeed,
    required this.circle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> progress;
  final List<_Particle> particles;
  final double seconds;

  _ConfettiPainter({
    required this.progress,
    required this.particles,
    required this.seconds,
  }) : super(repaint: progress);

  static const _drag = 2.0; // 空氣阻力
  static const _gravity = 0.9; // 螢幕高度 / 秒²

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value;
    if (p <= 0 || p >= 1) return;

    final t = p * seconds;
    final dragT = (1 - math.exp(-_drag * t)) / _drag;
    final fade = p < 0.75 ? 1.0 : (1 - (p - 0.75) / 0.25);
    final ox = size.width / 2;
    final oy = size.height * 0.45;
    final paint = Paint();

    for (final e in particles) {
      final x = ox + e.vx * size.height * dragT;
      final y = oy +
          e.vy * size.height * dragT +
          0.5 * _gravity * size.height * t * t;
      if (y > size.height + 40) continue;

      paint.color = e.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(e.rot0 + e.spin * t);
      if (e.circle) {
        canvas.drawCircle(Offset.zero, e.w / 2, paint);
      } else {
        // 縱向縮放模擬紙片翻面
        final flip = math.cos(e.flip0 + e.flipSpeed * t);
        canvas.scale(1, flip.abs().clamp(0.15, 1.0));
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: e.w, height: e.h),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.particles != particles || old.seconds != seconds;
}
