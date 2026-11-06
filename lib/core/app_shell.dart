import 'package:flutter/material.dart';
import '../features/habits/presentation/habit_form_page.dart';
import '../features/habits/presentation/today/today_page.dart';
import '../features/settings/settings_page.dart';
import 'glass_kit.dart';
import 'haptics.dart';
import 'motion.dart';
import 'strings.dart';
import 'tokens.dart';

/// 主框架:兩個分頁 + 浮動膠囊分頁列
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HabitFormPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    // 在設定分頁按返回,先回到「今天」,不直接離開 App
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      // 透明 Material:提供預設文字樣式,避免出現黃色雙底線
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _index,
                children: const [
                  TodayPage(),
                  SettingsPage(),
                ],
              ),
            ),
            Positioned(
              left: Gap.lg,
              right: Gap.lg,
              bottom: bottom + Gap.md,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FloatingTabBar(
                    index: _index,
                    onChanged: (i) => setState(() => _index = i),
                    items: [
                      FloatingTabItem(Icons.checklist_rounded, s.today),
                      FloatingTabItem(Icons.settings_rounded, s.settings),
                    ],
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.normal),
                    switchInCurve: Motion.enter,
                    switchOutCurve: Motion.exit,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: _index == 0
                        ? GlassIconButton(
                            key: const ValueKey('add'),
                            icon: Icons.add_rounded,
                            semanticLabel: s.addHabit,
                            onPressed: _openForm,
                          )
                        : const SizedBox(key: ValueKey('none'), width: 54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingTabItem {
  final IconData icon;
  final String label;
  const FloatingTabItem(this.icon, this.label);
}

/// 浮動膠囊分頁列:選中項為實心主色膠囊加文字,其餘只有圖示
class FloatingTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<FloatingTabItem> items;

  const FloatingTabBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 20,
      borderRadius: BorderRadius.circular(Radii.panel),
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            _TabButton(
              item: items[i],
              selected: i == index,
              onTap: () {
                if (i == index) return;
                Haptics.selection();
                onChanged(i);
              },
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final FloatingTabItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final c = IosColors.of(context);
    final fg = selected ? Colors.white : c.labelSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.normal),
          curve: Motion.enter,
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 14),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.panel),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 24, color: fg),
              AnimatedSize(
                duration: Motion.of(context, Motion.normal),
                curve: Motion.enter,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: TextStyle(
                            color: fg,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
