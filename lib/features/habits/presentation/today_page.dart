import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/glass_kit.dart';
import '../../../core/progress_ring.dart';
import '../../../core/strings.dart';
import '../domain/habit_style.dart';
import 'habit_detail_page.dart';
import 'habit_form_page.dart';
import 'habit_providers.dart';
import '../../settings/settings_page.dart';

class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage>
    with WidgetsBindingObserver {
  bool _celebrating = false;
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);

  /// 已滑掉、正在等資料庫刪除的習慣，先從畫面移除
  final _hidden = <int>{};

  String _dateText(BuildContext context) => DateFormat.yMMMd(
        Localizations.localeOf(context).toString(),
      ).format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(() {
      _offset.value = _scroll.hasClients ? _scroll.offset : 0;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  // App 回到前景時重新載入（處理跨日）
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(todayProvider.notifier).refresh();
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HabitFormPage()),
    );
  }

  /// 右滑刪除：先從畫面移除，再刪資料庫，並提供「復原」
  Future<void> _delete(HabitItem item) async {
    final id = item.habit.id!;
    final name = item.habit.name;
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(todayProvider.notifier);

    HapticFeedback.mediumImpact();
    setState(() => _hidden.add(id));
    try {
      final snap = await notifier.deleteWithSnapshot(id);
      messenger.clearSnackBars();
      if (snap != null) {
        messenger.showSnackBar(SnackBar(
          content: Text(s.deleted(name)),
          action: SnackBarAction(
            label: s.undo,
            onPressed: () => notifier.restoreDeleted(snap),
          ),
        ));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.deleteFailed(e))));
    } finally {
      if (mounted) setState(() => _hidden.remove(id));
    }
  }

  Widget _swipeToDelete(HabitItem item, Widget child) {
    return Dismissible(
      key: ValueKey('del_${item.habit.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(left: 24),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _delete(item),
      child: child,
    );
  }

  /// 全部完成時的慶祝動畫
  Future<void> _celebrate() async {
    if (_celebrating) return;
    _celebrating = true;
    HapticFeedback.heavyImpact();

    final reduce = MediaQuery.disableAnimationsOf(context);
    final nav = Navigator.of(context, rootNavigator: true);
    final s = S.of(context);
    var open = true;

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (open && mounted && nav.canPop()) nav.pop();
    });

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: s.celebrate,
      barrierColor: Colors.black38,
      transitionDuration:
          reduce ? Duration.zero : const Duration(milliseconds: 380),
      pageBuilder: (ctx, _, _) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassContainer(
            borderRadius: const BorderRadius.all(Radius.circular(28)),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u{1F389}', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                Text(s.allDoneTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
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
    _celebrating = false;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final async = ref.watch(todayProvider);

    ref.listen(todayProvider, (prev, next) {
      final wd = DateTime.now().weekday;
      final before = prev?.value?.where((e) => e.habit.runsOn(wd)).toList();
      final after = next.value?.where((e) => e.habit.runsOn(wd)).toList();
      if (before == null || after == null || after.isEmpty) return;
      final wasAll = before.isNotEmpty && before.every((e) => e.doneToday);
      final nowAll = after.every((e) => e.doneToday);
      if (!wasAll && nowAll) _celebrate();
    });

    return GlassScaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: async.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Center(child: Text(s.loadFailed(e))),
              data: (all) => _buildContent(context, all),
            ),
          ),
          _buildMiniBar(context),
          // 空狀態中央已有「新增第一個習慣」，不重複顯示膠囊
          if (async.value?.isNotEmpty ?? false)
            Positioned(
              right: 20,
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              child: GlassPill(
                icon: Icons.add_rounded,
                label: s.addHabit,
                onPressed: _openForm,
              ),
            ),
        ],
      ),
    );
  }

  /// 捲動超過大標題後，從頂部淡入的迷你標題列
  Widget _buildMiniBar(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final top = MediaQuery.paddingOf(context).top;
    final title = S.of(context).today;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<double>(
        valueListenable: _offset,
        builder: (context, offset, _) {
          final t = ((offset - 50) / 40).clamp(0.0, 1.0);
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
                              ? const Color(0xFF0B0F14)
                              : const Color(0xFFF4F6F8))
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

  Widget _buildHeader(
    ThemeData theme,
    List<HabitItem> scheduled,
    int done,
  ) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateText(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scheduled.isEmpty ? s.restToday : s.today,
                      style: theme.textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              GlassIconButton(
                blur: null,
                icon: Icons.settings_outlined,
                semanticLabel: s.settings,
                onPressed: _openSettings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (scheduled.isEmpty)
            Text(
              s.noScheduled,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            )
          else
            Semantics(
              label: s.progressLabel(done, scheduled.length),
              excludeSemantics: true,
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ProgressRing(
                      progress: done / scheduled.length,
                      child: Text(
                        '${(done / scheduled.length * 100).round()}%',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.doneOf(done, scheduled.length),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            done == scheduled.length
                                ? s.allDoneEmoji
                                : s.remaining(scheduled.length - done),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<HabitItem> allItems) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final all = allItems.where((i) => !_hidden.contains(i.habit.id)).toList();
    final wd = DateTime.now().weekday;
    final scheduled = all.where((i) => i.habit.runsOn(wd)).toList();
    final resting = all.where((i) => !i.habit.runsOn(wd)).toList();

    if (all.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checklist_rounded,
                      size: 72,
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(s.noHabits, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    s.noHabitsSub,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add),
                    label: Text(s.addFirst),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 20,
            child: GlassIconButton(
              blur: null,
              icon: Icons.settings_outlined,
              semanticLabel: s.settings,
              onPressed: _openSettings,
            ),
          ),
        ],
      );
    }

    final done = scheduled.where((i) => i.doneToday).length;

    return ReorderableListView.builder(
      scrollController: _scroll,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      header: _buildHeader(theme, scheduled, done),
      proxyDecorator: (child, index, anim) => AnimatedBuilder(
        animation: anim,
        builder: (ctx, c) {
          final t = Curves.easeOutCubic.transform(anim.value);
          return Transform.scale(
            scale: 1 + 0.03 * t,
            child: Material(type: MaterialType.transparency, child: c),
          );
        },
        child: child,
      ),
      footer: resting.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(s.restToday, style: theme.textTheme.titleMedium),
                ),
                for (final item in resting)
                  _swipeToDelete(
                    item,
                    _HabitCard(
                      key: ValueKey('rest_${item.habit.id}'),
                      item: item,
                      resting: true,
                    ),
                  ),
              ],
            ),
      itemCount: scheduled.length,
      onReorderItem: (o, n) {
        final ids = scheduled.map((e) => e.habit.id!).toList();
        final moved = ids.removeAt(o);
        ids.insert(n, moved);
        ref.read(todayProvider.notifier).reorderVisible(ids);
      },
      itemBuilder: (context, i) {
        final item = scheduled[i];
        return _swipeToDelete(
          item,
          _HabitCard(key: ValueKey(item.habit.id), item: item),
        );
      },
    );
  }
}

class _HabitCard extends ConsumerStatefulWidget {
  final HabitItem item;
  final bool resting;
  const _HabitCard({super.key, required this.item, this.resting = false});

  @override
  ConsumerState<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<_HabitCard> {
  bool _down = false;

  /// 單次習慣:原本的勾選按鈕
  Widget _buildToggleButton({
    required HabitItem item,
    required Color color,
    required ColorScheme scheme,
    required bool reduce,
    required bool resting,
  }) {
    final s = S.of(context);
    final done = item.doneToday;
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: done ? s.uncheck : s.check,
        icon: AnimatedSwitcher(
          duration:
              reduce ? Duration.zero : const Duration(milliseconds: 320),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: child,
          ),
          child: Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            key: ValueKey(done),
            size: 32,
            color: done
                ? color
                : scheme.outline.withValues(alpha: resting ? 0.5 : 1.0),
          ),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          ref
              .read(todayProvider.notifier)
              .toggle(item.habit.id!, item.doneToday);
        },
      ),
    );
  }

  /// 多次習慣:− 按鈕加上進度環 + 按鈕
  Widget _buildCounterButtons({
    required HabitItem item,
    required Color color,
    required ColorScheme scheme,
    required bool resting,
  }) {
    final s = S.of(context);
    final target = item.habit.dailyTarget;
    final count = item.todayCount;
    final done = item.doneToday;
    final ringColor = resting ? color.withValues(alpha: 0.5) : color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (count > 0)
          SizedBox(
            width: 40,
            height: 48,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: s.decrease,
              icon: const Icon(Icons.remove_circle_outline, size: 24),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(todayProvider.notifier).decrement(item.habit.id!);
              },
            ),
          ),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            tooltip: done ? s.targetReached : s.tapOnce(count, target),
            onPressed: done
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(todayProvider.notifier)
                        .increment(item.habit.id!);
                  },
            icon: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    value: (count / target).clamp(0.0, 1.0),
                    strokeWidth: 3.5,
                    backgroundColor: scheme.outline.withValues(alpha: 0.25),
                    color: ringColor,
                  ),
                ),
                Icon(done ? Icons.check : Icons.add,
                    size: 18, color: ringColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final item = widget.item;
    final resting = widget.resting;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = Color(item.habit.colorValue);
    final done = item.doneToday;
    final reduce = MediaQuery.disableAnimationsOf(context);

    final target = item.habit.dailyTarget;
    final multi = target > 1;

    final titleColor =
        resting ? scheme.onSurface.withValues(alpha: 0.5) : scheme.onSurface;
    final subColor =
        scheme.onSurfaceVariant.withValues(alpha: resting ? 0.6 : 1.0);
    final status = resting
        ? s.restToday
        : done
            ? s.completed
            : multi
                ? '${item.todayCount}/$target'
                : s.notDone;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration:
              reduce ? Duration.zero : const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: done && !resting
                ? color.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onHighlightChanged: (v) => setState(() => _down = v),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HabitDetailPage(habitId: item.habit.id!),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              color.withValues(alpha: resting ? 0.08 : 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          iconFor(item.habit.iconKey),
                          color:
                              resting ? color.withValues(alpha: 0.5) : color,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.habit.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: titleColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${s.streak(item.currentStreak)} · $status',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: subColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (multi)
                        _buildCounterButtons(
                          item: item,
                          color: color,
                          scheme: scheme,
                          resting: resting,
                        )
                      else
                        _buildToggleButton(
                          item: item,
                          color: color,
                          scheme: scheme,
                          reduce: reduce,
                          resting: resting,
                        ),
                    ],
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
