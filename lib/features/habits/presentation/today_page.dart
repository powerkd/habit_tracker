import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/glass_kit.dart';
import '../../../core/progress_ring.dart';
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

  String get dateText {
    final now = DateTime.now();
    return '${now.year}年${now.month}月${now.day}日';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  /// 全部完成時的慶祝動畫
  /// 只用路由本身的動畫（淡入＋縮放），計時器放在外面，避免重建時重複 pop
  Future<void> _celebrate() async {
    if (_celebrating) return;
    _celebrating = true;
    HapticFeedback.heavyImpact();

    final reduce = MediaQuery.disableAnimationsOf(context);
    final nav = Navigator.of(context, rootNavigator: true);
    var open = true;

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (open && mounted && nav.canPop()) nav.pop();
    });

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '慶祝',
      barrierColor: Colors.black38,
      transitionDuration:
          reduce ? Duration.zero : const Duration(milliseconds: 380),
      pageBuilder: (ctx, _, _) => const Center(
        child: Material(
          color: Colors.transparent,
          child: GlassContainer(
            borderRadius: BorderRadius.all(Radius.circular(28)),
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎉', style: TextStyle(fontSize: 64)),
                SizedBox(height: 8),
                Text('今天全部完成！',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
    final async = ref.watch(todayProvider);

    // 只在「從未全部完成」變成「全部完成」的那一刻觸發
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
              // 重新載入時保留舊資料，不閃轉圈
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Center(child: Text('載入失敗：$e')),
              data: (all) => _buildContent(context, all),
            ),
          ),
          Positioned(
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            child: GlassIconButton(
              icon: Icons.add_rounded,
              semanticLabel: '新增習慣',
              onPressed: _openForm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    List<HabitItem> scheduled,
    int done,
  ) {
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
                      dateText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scheduled.isEmpty ? '今天休息' : '今天',
                      style: theme.textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              GlassIconButton(
                blur: null, // 在清單裡捲動，不做即時模糊
                icon: Icons.settings_outlined,
                semanticLabel: '設定',
                onPressed: _openSettings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (scheduled.isEmpty)
            Text(
              '沒有排程的習慣',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            )
          else
            Semantics(
              label: '今日進度 $done／${scheduled.length}',
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
                            '已完成 $done／${scheduled.length}',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            done == scheduled.length
                                ? '今天全部完成 🎉'
                                : '還差 ${scheduled.length - done} 個',
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

  Widget _buildContent(BuildContext context, List<HabitItem> all) {
    final theme = Theme.of(context);
    final wd = DateTime.now().weekday;
    final scheduled = all.where((i) => i.habit.runsOn(wd)).toList();
    final resting = all.where((i) => !i.habit.runsOn(wd)).toList();

    // 空狀態：仍保留設定入口（設定頁有備份匯入）
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
                  Text('還沒有任何習慣', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '從一個小習慣開始,\n每天打卡,累積連續天數。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add),
                    label: const Text('新增第一個習慣'),
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
              semanticLabel: '設定',
              onPressed: _openSettings,
            ),
          ),
        ],
      );
    }

    final done = scheduled.where((i) => i.doneToday).length;

    return ReorderableListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      header: _buildHeader(theme, scheduled, done),
      // 拖曳時輕微放大，取代預設的陰影
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
                  child: Text('今天休息', style: theme.textTheme.titleMedium),
                ),
                for (final item in resting)
                  _HabitCard(
                    key: ValueKey('rest_${item.habit.id}'),
                    item: item,
                    resting: true,
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
        return _HabitCard(key: ValueKey(item.habit.id), item: item);
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final resting = widget.resting;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = Color(item.habit.colorValue);
    final done = item.doneToday;
    final reduce = MediaQuery.disableAnimationsOf(context);

    final titleColor =
        resting ? scheme.onSurface.withValues(alpha: 0.5) : scheme.onSurface;
    final subColor =
        scheme.onSurfaceVariant.withValues(alpha: resting ? 0.6 : 1.0);
    final status = resting
        ? '今天休息'
        : done
            ? '已完成'
            : '未完成';

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
                              '🔥 ${item.currentStreak} 天 · $status',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: subColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          tooltip: done ? '取消完成' : '標記完成',
                          icon: AnimatedSwitcher(
                            duration: reduce
                                ? Duration.zero
                                : const Duration(milliseconds: 320),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(
                              scale: CurvedAnimation(
                                  parent: anim, curve: Curves.easeOutBack),
                              child: child,
                            ),
                            child: Icon(
                              done
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              key: ValueKey(done),
                              size: 32,
                              color: done
                                  ? color
                                  : scheme.outline
                                      .withValues(alpha: resting ? 0.5 : 1.0),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(todayProvider.notifier)
                                .toggle(item.habit.id!, item.doneToday);
                          },
                        ),
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