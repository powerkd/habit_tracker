import 'dart:math' show max;
import 'dart:ui';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'motion.dart';
import 'tokens.dart';

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
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          side: BorderSide(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.15),
          ),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E252E) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.panel),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF2A323C) : const Color(0xFF1F2933),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
        actionTextColor: const Color(0xFF2DD4BF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.control),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF1E252E) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(Radii.panel)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: (isDark ? Colors.white : Colors.black)
            .withValues(alpha: isDark ? 0.07 : 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        thickness: 0.5,
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
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
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// 玻璃材質容器
/// blur 為 null(預設)時不做即時模糊,只用半透明填色加高光邊框,效能接近零成本。
/// 只有浮在內容上方的元件(按鈕、彈窗)才傳入 blur。
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double? blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(Radii.panel)),
    this.padding = const EdgeInsets.all(12),
    this.blur,
  });

  Radius _inner(Radius r) => Radius.circular(max(0.0, r.x - 1));

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final useBlur = blur != null && !reduce;

    // 沒有模糊時,填色稍微不透明,避免背景光暈影響文字可讀性
    final fill = dark
        ? Colors.white.withValues(alpha: useBlur ? 0.08 : 0.07)
        : Colors.white.withValues(alpha: useBlur ? 0.55 : 0.72);
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
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
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

    // 沒有模糊就不需要 ClipRRect,少一次裁切
    if (!useBlur) return RepaintBoundary(child: content);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
          child: content,
        ),
      ),
    );
  }
}

/// 玻璃圓形按鈕(取代 FAB)
class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final double? blur;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.blur = 16,
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
      excludeSemantics: true,
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
          duration: Motion.of(context, Motion.fast),
          curve: Motion.enter,
          child: GlassContainer(
            blur: widget.blur,
            borderRadius: BorderRadius.circular(Radii.panel),
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

/// 自帶背景的 Scaffold。背景在 Scaffold 外層,連 AppBar 區域都不透明,
/// 所以頁面轉場時不會透出前一頁。
class GlassScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const GlassScaffold({super.key, this.appBar, required this.body});

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
      ),
    );
  }
}

/// 玻璃膠囊按鈕(圖示+文字),浮在清單上方,所以保留模糊
class GlassPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const GlassPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<GlassPill> createState() => _GlassPillState();
}

class _GlassPillState extends State<GlassPill> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
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
          scale: _down ? 0.94 : 1,
          duration: Motion.of(context, Motion.fast),
          curve: Motion.enter,
          child: GlassContainer(
            blur: 16,
            borderRadius: BorderRadius.circular(Radii.panel),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 54,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: accent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
