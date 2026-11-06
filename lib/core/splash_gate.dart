import 'dart:async';

import 'package:flutter/material.dart';

/// 啟動載入動畫。子畫面在底下同時建構,動畫結束後淡出露出。
/// [ready] 可傳入初始化的 Future,動畫會等它完成才淡出(至少播完 [minDuration])。
class SplashGate extends StatefulWidget {
  final Widget child;
  final String title;
  final Future<void>? ready;
  final Duration minDuration;

  const SplashGate({
    super.key,
    required this.child,
    this.title = 'Habit Tracker',
    this.ready,
    this.minDuration = const Duration(milliseconds: 1100),
  });

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  bool _fading = false; // 開始淡出
  bool _removed = false; // 已完全移除

  late final Animation<double> _scale = Tween<double>(begin: 0.6, end: 1.0)
      .animate(CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
  ));
  late final Animation<double> _check = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
  );
  late final Animation<double> _text = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
    _run();
  }

  Future<void> _run() async {
    try {
      await Future.wait([
        Future<void>.delayed(widget.minDuration),
        if (widget.ready != null) widget.ready!,
      ]);
    } catch (_) {
      // 初始化失敗也要進首頁,錯誤由首頁自行處理
    }
    if (mounted) setState(() => _fading = true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 減少動態效果:略過動畫
    if (MediaQuery.disableAnimationsOf(context) || _removed) {
      return widget.child;
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final bg = dark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final fg = dark ? Colors.white : Colors.black;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: _fading,
          child: AnimatedOpacity(
            opacity: _fading ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            onEnd: () {
              if (_fading && mounted) setState(() => _removed = true);
            },
            child: ColoredBox(
              color: bg,
              child: Center(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _scale.value,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: CustomPaint(
                            painter: _CheckPainter(_check.value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: _text.value,
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: fg,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double t;
  _CheckPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.28, h * 0.52)
      ..lineTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.74, h * 0.34);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * t), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t;
}
