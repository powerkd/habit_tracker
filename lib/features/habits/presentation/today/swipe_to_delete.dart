import 'package:flutter/material.dart';
import '../../../../core/haptics.dart';
import '../../../../core/motion.dart';
import '../../../../core/tokens.dart';

/// 右滑刪除。滑過門檻時垃圾桶放大、背景變深並震動一次,
/// 滑回門檻內會再輕震一次,表示已取消。
class SwipeToDelete extends StatefulWidget {
  final int habitId;
  final VoidCallback onDelete;
  final Widget child;

  const SwipeToDelete({
    super.key,
    required this.habitId,
    required this.onDelete,
    required this.child,
  });

  @override
  State<SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<SwipeToDelete> {
  final _progress = ValueNotifier<double>(0);
  final _reached = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _progress.dispose();
    _reached.dispose();
    super.dispose();
  }

  void _onUpdate(DismissUpdateDetails d) {
    if (d.reached != d.previousReached) {
      if (d.reached) {
        Haptics.medium();
      } else {
        Haptics.light();
      }
    }
    _progress.value = d.progress;
    _reached.value = d.reached;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${widget.habitId}'),
      direction: DismissDirection.startToEnd,
      onUpdate: _onUpdate,
      onDismissed: (_) => widget.onDelete(),
      background: AnimatedBuilder(
        animation: Listenable.merge([_progress, _reached]),
        builder: (context, _) {
          final reached = _reached.value;
          final fadeIn = (_progress.value * 3).clamp(0.0, 1.0);
          final dur = Motion.of(context, Motion.fast);

          return AnimatedContainer(
            duration: dur,
            curve: Motion.enter,
            margin: const EdgeInsets.only(bottom: Gap.md),
            padding: const EdgeInsets.only(left: Gap.xl),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Tone.danger.withValues(alpha: reached ? 1.0 : 0.55),
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            child: Opacity(
              opacity: fadeIn,
              child: AnimatedScale(
                scale: reached ? 1.3 : 1.0,
                duration: dur,
                curve: Curves.easeOutBack,
                child: Icon(
                  reached
                      ? Icons.delete_rounded
                      : Icons.delete_outline_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
      child: widget.child,
    );
  }
}
