import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'tokens.dart';

/// iOS 風格的頂部提示卡片。同一時間只顯示一個,新的會取代舊的。
class Toast {
  Toast._();

  static OverlayEntry? _entry;

  /// 用 [context] 找到最上層的 Overlay 顯示。
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    showOn(
      Overlay.of(context, rootOverlay: true),
      message: message,
      icon: icon,
      iconColor: iconColor,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// 直接指定 Overlay。適合在 await 之後使用:
  /// 先在 await 之前取得 OverlayState,就不用再碰 BuildContext。
  static void showOn(
    OverlayState overlay, {
    required String message,
    IconData? icon,
    Color? iconColor,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    _removeCurrent();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        icon: icon,
        iconColor: iconColor,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration ??
            (actionLabel != null
                ? const Duration(seconds: 4)
                : const Duration(milliseconds: 2500)),
        onClosed: () {
          if (identical(_entry, entry)) {
            _entry = null;
            entry.remove();
          }
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void _removeCurrent() {
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onClosed;

  const _ToastView({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onClosed,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(widget.duration, _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    await _c.reverse();
    if (mounted) widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final top = MediaQuery.paddingOf(context).top;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final card = IosColors.of(context).card;

    final slide = Tween<Offset>(
      begin: reduce ? Offset.zero : const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(_curve);

    return Positioned(
      top: top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: _curve,
          child: GestureDetector(
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -150) _close();
            },
            child: Semantics(
              liveRegion: true,
              child: Material(
                type: MaterialType.transparency,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.card),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: card.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(Radii.card),
                        border: Border.all(
                          color: (dark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 22,
                              color: widget.iconColor ?? scheme.primary,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              widget.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (widget.actionLabel != null)
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: scheme.primary,
                                minimumSize: const Size(0, 36),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onPressed: () {
                                widget.onAction?.call();
                                _close();
                              },
                              child: Text(widget.actionLabel!),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
