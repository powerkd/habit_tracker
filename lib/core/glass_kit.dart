import 'dart:math' show max;
import 'dart:ui';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全域主色,要換色只改這裡
const kAccent = Color(0xFF14B8A6);

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: kAccent,
      brightness: b,
    ).copyWith(
      primary: isDark ? const Color(0xFF2DD4BF) : kAccent,
      surface: isDark ? const Color(0xFF161B22) : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 17),
        bodyMedium: TextStyle(fontSize: 15),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}

/// 整頁背景:中性底色加柔和漸層光暈
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: dark ? const Color(0xFF0B0F14) : const Color(0xFFF4F6F8),
          ),
        ),
        Positioned(
          top: -120,
          left: -100,
          child: _Glow(
            size: 360,
            color: dark ? const Color(0xFF0F3D3A) : const Color(0xFFCFF5EF),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -120,
          child: _Glow(
            size: 400,
            color: dark ? const Color(0xFF14213D) : const Color(0xFFD9E6FF),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// 玻璃材質容器
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.padding = const EdgeInsets.all(12),
    this.blur = 24,
  });

  Radius _inner(Radius r) => Radius.circular(max(0.0, r.x - 1));

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.of(context).disableAnimations;

    final fill = Colors.white.withValues(alpha: dark ? 0.08 : 0.55);
    final hiA = Colors.white.withValues(alpha: dark ? 0.25 : 0.8);
    final hiB = Colors.white.withValues(alpha: dark ? 0.04 : 0.15);
    final solid = dark ? const Color(0xFF1E252E) : Colors.white;

    // 外層漸層當作 1px 高光邊框,內層填色
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hiA, hiB],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: reduce ? solid : fill,
            borderRadius: BorderRadius.only(
              topLeft: _inner(borderRadius.topLeft),
              topRight: _inner(borderRadius.topRight),
              bottomLeft: _inner(borderRadius.bottomLeft),
              bottomRight: _inner(borderRadius.bottomRight),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: reduce
          ? content
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: content,
            ),
    );
  }
}

/// 玻璃圓形按鈕(取代 FAB)
class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _down ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: GlassContainer(
            borderRadius: BorderRadius.circular(28),
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 54,
              height: 54,
              child: Icon(widget.icon, color: accent, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
