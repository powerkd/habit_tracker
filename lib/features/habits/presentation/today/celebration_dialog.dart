import 'package:flutter/material.dart';
import '../../../../core/confetti.dart';
import '../../../../core/glass_kit.dart';
import '../../../../core/haptics.dart';
import '../../../../core/motion.dart';
import '../../../../core/strings.dart';
import '../../../../core/tokens.dart';

/// 全部完成時的慶祝彈窗(含彩帶),約 2.4 秒後自動關閉。
/// 彈窗關閉後 Future 才會完成。
Future<void> showCelebrationDialog(BuildContext context) async {
  Haptics.heavy();

  final reduce = MediaQuery.disableAnimationsOf(context);
  final nav = Navigator.of(context, rootNavigator: true);
  final s = S.of(context);
  var open = true;

  Future.delayed(const Duration(milliseconds: 2400), () {
    if (open && nav.mounted && nav.canPop()) nav.pop();
  });

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: s.celebrate,
    barrierColor: Colors.black38,
    transitionDuration: reduce ? Duration.zero : Motion.slow,
    pageBuilder: (ctx, _, _) => Stack(
      fit: StackFit.expand,
      children: [
        const ConfettiBurst(),
        Center(
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              blur: 16,
              borderRadius: BorderRadius.circular(Radii.panel),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.celebration_rounded,
                      size: 64, color: Tone.trophy),
                  const SizedBox(height: 8),
                  Text(
                    s.allDoneTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Motion.emphasize,
        reverseCurve: Motion.exit,
      );
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );

  open = false;
}
