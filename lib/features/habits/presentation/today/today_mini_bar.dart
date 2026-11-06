import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import '../../../../core/strings.dart';

/// 捲動超過大標題後,從頂部淡入的迷你標題列。
/// [offset] 為列表的捲動位置。
class TodayMiniBar extends StatelessWidget {
  final ValueListenable<double> offset;
  const TodayMiniBar({super.key, required this.offset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final top = MediaQuery.paddingOf(context).top;
    final title = S.of(context).today;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<double>(
        valueListenable: offset,
        builder: (context, value, _) {
          final t = ((value - 50) / 40).clamp(0.0, 1.0);
          if (t == 0) return const SizedBox.shrink();

          return IgnorePointer(
            child: Opacity(
              opacity: t,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: top + 48,
                    padding: EdgeInsets.only(top: top),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (dark
                              ? const Color(0xFF000000)
                              : const Color(0xFFF2F2F7))
                          .withValues(alpha: 0.8),
                      border: Border(
                        bottom: BorderSide(
                          color: (dark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
