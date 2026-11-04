import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'motion.dart';

class CheckButton extends StatefulWidget {
  final bool checked;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final String semanticLabel;

  const CheckButton({
    super.key,
    required this.checked,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
    this.size = 44,
  });

  @override
  State<CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<CheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Motion.normal,
      value: widget.checked ? 1 : 0, // 初始狀態不播動畫
    );
  }

  @override
  void didUpdateWidget(CheckButton old) {
    super.didUpdateWidget(old);
    if (old.checked == widget.checked) return;
    // 外部狀態改變(包含復原、跨日)也要同步,動畫從目前值接續
    final d = Motion.of(context, Motion.normal);
    _c.duration = d;
    widget.checked ? _c.forward() : _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _handleTap() {
    // 打卡用較明顯的回饋,取消用較輕的
    widget.checked
        ? HapticFeedback.selectionClick()
        : HapticFeedback.mediumImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onColor =
        widget.color.computeLuminance() > 0.6 ? Colors.black87 : Colors.white;
    // 填滿:曲線 enter;圖示:曲線 emphasize,延後一點開始
    final fill = CurvedAnimation(parent: _c, curve: Motion.enter);
    final icon = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.3, 1.0, curve: Motion.emphasize),
    );

    return Semantics(
      button: true,
      checked: widget.checked,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        // 外層維持 44 以上的點擊範圍
        child: SizedBox(
          width: widget.size < 44 ? 44 : widget.size,
          height: widget.size < 44 ? 44 : widget.size,
          child: Center(
            child: RepaintBoundary(
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外框
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: SizedBox.expand(),
                    ),
                    // 由內向外擴張的填色
                    ScaleTransition(
                      scale: fill,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    // 勾選圖示:0.8 → 1.0 回彈,同時淡入
                    FadeTransition(
                      opacity: icon.drive(
                          Tween(begin: 0.0, end: 1.0)
                              .chain(CurveTween(curve: Curves.easeOut))),
                      child: ScaleTransition(
                        scale: icon.drive(Tween(begin: 0.8, end: 1.0)),
                        child: Icon(Icons.check,
                            size: widget.size * 0.55, color: onColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
