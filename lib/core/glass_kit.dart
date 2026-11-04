import 'dart:math' show max;
import 'dart:ui';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'haptics.dart';
import 'motion.dart';
import 'tokens.dart';

/// 預設主色(iOS Blue)。使用者選的主題色由 AppTheme 參數傳入
const kAccent = Color(0xFF007AFF); // 淺色
const kAccentDark = Color(0xFF0A84FF); // 深色

class AppTheme {
  static ThemeData light([Color accent = kAccent]) =>
      _build(Brightness.light, accent);
  static ThemeData dark([Color accent = kAccentDark]) =>
      _build(Brightness.dark, accent);

  static ThemeData _build(Brightness b, Color accent) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: b,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      error: isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
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
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.panel),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // 抬高,避免被底部浮動分頁列蓋住
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        elevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
        // 深色底的 SnackBar 上,淺色主題色對比不足,所以固定用較亮的 iOS Blue
        actionTextColor: isDark ? accent : kAccentDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.control),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
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

/// 整頁背景:iOS 的純灰/純黑,不加彩色光暈
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
            color: dark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// 玻璃材質容器
/// blur 為 null(預設)時不做即時模糊,使用不透明的 iOS 卡片色加細邊。
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

    final base = dark ? const Color(0xFF1C1C1E) : Colors.white;
    final fill = base.withValues(alpha: useBlur ? 0.72 : 1.0);
    final edgeA = (dark ? Colors.white : Colors.black)
        .withValues(alpha: dark ? 0.12 : 0.07);
    final edgeB = (dark ? Colors.white : Colors.black)
        .withValues(alpha: dark ? 0.05 : 0.03);

    // 外層漸層當作 1px 邊框,內層填色。iOS 卡片是平的,不加陰影
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [edgeA, edgeB],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: reduce ? base : fill,
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

/// 玻璃圓形按鈕
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
          Haptics.light();
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
          Haptics.light();
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

/// 區段標題:卡片外上方的小灰字
class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = IosColors.of(context);
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Gap.lg + Gap.xs, Gap.xl, Gap.lg, Gap.sm),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: c.labelSecondary,
        ),
      ),
    );
  }
}

/// 分組卡片:多列之間用縮排細線分隔,無邊框無陰影
class GroupedCard extends StatelessWidget {
  final List<Widget> children;
  const GroupedCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = IosColors.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Padding(
          padding: const EdgeInsets.only(left: Gap.lg),
          child: Divider(height: 0.5, thickness: 0.5, color: c.separator),
        ));
      }
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Gap.lg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// 單列:左標題(可含副標),右側為數值或控制項
class GroupedRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final Color? iconColor;
  final bool destructive;
  final VoidCallback? onTap;

  const GroupedRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    this.iconColor,
    this.destructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = IosColors.of(context);
    final titleColor = destructive ? Tone.danger : c.label;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Gap.lg, vertical: Gap.md + 2),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 22,
                  color: destructive
                      ? Tone.danger
                      : (iconColor ?? Theme.of(context).colorScheme.primary)),
              const SizedBox(width: Gap.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 17, color: titleColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 13, color: c.labelSecondary)),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// 右側「數值加上下箭頭」,例如 System ⌃
class ValueLabel extends StatelessWidget {
  final String text;
  final bool accent; // true=藍字(可選單),false=灰字
  const ValueLabel(this.text, {super.key, this.accent = true});

  @override
  Widget build(BuildContext context) {
    final c = IosColors.of(context);
    final color =
        accent ? Theme.of(context).colorScheme.primary : c.labelSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: TextStyle(fontSize: 17, color: color)),
        const SizedBox(width: 2),
        Icon(Icons.unfold_more, size: 18, color: color),
      ],
    );
  }
}
