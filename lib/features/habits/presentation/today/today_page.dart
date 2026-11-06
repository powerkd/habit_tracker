import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_settings.dart';
import '../../../../core/glass_kit.dart';
import '../../../../core/haptics.dart';
import '../../../../core/locale_provider.dart';
import '../../../../core/motion.dart';
import '../../../../core/reveal.dart';
import '../../../../core/routes.dart';
import '../../../../core/strings.dart';
import '../../../../core/toast.dart';
import '../../../../core/tokens.dart';
import '../../domain/today_logic.dart';
import '../habit_form_page.dart';
import '../habit_providers.dart';
import 'celebration_dialog.dart';
import 'habit_card.dart';
import 'swipe_to_delete.dart';
import 'today_empty_view.dart';
import 'today_header.dart';
import 'today_mini_bar.dart';
import 'today_skeleton.dart';

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

  /// 已滑掉、正在等資料庫刪除的習慣,先從畫面移除
  final _hidden = <int>{};

  /// 已經顯示過的習慣 id。不在這裡面的新習慣才播放出現動畫。
  final _known = <int>{};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(() {
      // 淡入淡出切換時,可能短暫有兩個列表共用同一個 controller
      _offset.value =
          _scroll.hasClients ? _scroll.positions.last.pixels : 0;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  // App 回到前景時重新載入(處理跨日)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(todayProvider.notifier).refresh();
    }
  }

  /// C1:新增表單從下方升起
  void _openForm() {
    Navigator.push(
      context,
      appRoute(const HabitFormPage(), fullscreen: true),
    );
  }

  // ───────────── 刪除 ─────────────

  /// 右滑刪除:先從畫面移除,再刪資料庫,並提供「復原」。
  /// 震動已在滑過門檻時由 SwipeToDelete 觸發,這裡不再重複。
  Future<void> _delete(HabitItem item) async {
    final id = item.habit.id!;
    final name = item.habit.name;
    final s = S.of(context);
    // 在 await 之前先取得,之後不必再用 BuildContext
    final overlay = Overlay.of(context, rootOverlay: true);
    final notifier = ref.read(todayProvider.notifier);

    setState(() => _hidden.add(id));
    try {
      final snap = await notifier.deleteWithSnapshot(id);
      if (snap != null) {
        Toast.showOn(
          overlay,
          message: s.deleted(name),
          icon: Icons.delete_outline_rounded,
          iconColor: Tone.danger,
          actionLabel: s.undo,
          onAction: () => notifier.restoreDeleted(snap),
        );
      }
    } catch (e) {
      Toast.showOn(
        overlay,
        message: s.deleteFailed(e),
        icon: Icons.error_outline_rounded,
        iconColor: Tone.danger,
      );
    } finally {
      if (mounted) setState(() => _hidden.remove(id));
    }
  }

  /// 一列:出現動畫(B3) + 右滑刪除。
  /// ReorderableListView 要求最外層有 key,所以 key 放在這裡。
  Widget _row(HabitItem item, Widget card, Set<int> fresh) {
    final id = item.habit.id!;
    return AppearOnMount(
      key: ValueKey('row_$id'),
      animate: fresh.contains(id),
      child: SwipeToDelete(
        habitId: id,
        onDelete: () => _delete(item),
        child: card,
      ),
    );
  }

  // ───────────── 里程碑 / 慶祝 ─────────────

  Map<int, int> _streaks(List<HabitItem> l) =>
      {for (final e in l) e.habit.id!: e.currentStreak};

  void _checkMilestones(List<HabitItem>? prev, List<HabitItem>? next) {
    if (prev == null || next == null) return;
    if (!ref.read(appSettingsProvider).milestones) return;
    final hit = findMilestone(_streaks(prev), _streaks(next));
    if (hit == null) return;
    final name = next.firstWhere((e) => e.habit.id == hit.habitId).habit.name;
    _showMilestone(hit, name);
  }

  Future<void> _showMilestone(MilestoneHit hit, String name) async {
    final prefs = ref.read(prefsProvider);
    final key = milestoneKey(hit.habitId, hit.days);
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);
    if (!mounted) return;

    Haptics.medium();
    Toast.show(
      context,
      message: S.of(context).milestone(name, hit.days),
      icon: Icons.local_fire_department_rounded,
      iconColor: Tone.fire,
    );
  }

  void _checkAllDone(List<HabitItem>? prev, List<HabitItem>? next) {
    if (prev == null || next == null) return;
    final wd = DateTime.now().weekday;
    Iterable<bool> doneOf(List<HabitItem> l) =>
        l.where((e) => e.habit.runsOn(wd)).map((e) => e.doneToday);
    if (becameAllDone(before: doneOf(prev), after: doneOf(next))) {
      _celebrateOnce();
    }
  }

  /// 每天只慶祝一次;取消後再完成不會重複彈窗
  Future<void> _celebrateOnce() async {
    if (!ref.read(appSettingsProvider).celebrate) return;
    final prefs = ref.read(prefsProvider);
    final key = celebratedKey(DateTime.now());
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);
    if (!mounted || _celebrating) return;
    _celebrating = true;
    try {
      await showCelebrationDialog(context);
    } finally {
      _celebrating = false;
    }
  }

  // ───────────── build ─────────────

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final async = ref.watch(todayProvider);

    ref.listen(todayProvider, (prev, next) {
      _checkMilestones(prev?.value, next.value);
      _checkAllDone(prev?.value, next.value);
    });

    // B4:骨架 / 內容 / 空狀態之間用淡入淡出交接。
    final body = async.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const TodaySkeleton(key: ValueKey('loading')),
      error: (e, _) => Center(
        key: const ValueKey('error'),
        child: Text(s.loadFailed(e)),
      ),
      data: _buildContent,
    );

    return GlassScaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.normal),
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              child: body,
            ),
          ),
          TodayMiniBar(offset: _offset),
        ],
      ),
    );
  }

  Widget _buildContent(List<HabitItem> allItems) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final showRest = ref.watch(appSettingsProvider.select((v) => v.showRest));
    final all = allItems.where((i) => !_hidden.contains(i.habit.id)).toList();

    // B3:找出「新出現」的習慣。第一次載入時全部視為已知,不播動畫。
    final ids = all.map((e) => e.habit.id!).toSet();
    final fresh = _initialized ? ids.difference(_known) : <int>{};
    _known
      ..retainAll(ids)
      ..addAll(ids);
    _initialized = true;

    if (all.isEmpty) {
      return TodayEmptyView(key: const ValueKey('empty'), onAdd: _openForm);
    }

    final parts = splitByWeekday<HabitItem>(
      all,
      DateTime.now().weekday,
      (i, wd) => i.habit.runsOn(wd),
    );
    final scheduled = parts.scheduled;
    final resting = parts.resting;
    final done = scheduled.where((i) => i.doneToday).length;

    return ReorderableListView.builder(
      key: const ValueKey('list'),
      scrollController: _scroll,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      header: TodayHeader(scheduledCount: scheduled.length, done: done),
      proxyDecorator: habitDragDecorator,
      onReorderStart: (_) => Haptics.light(),
      onReorderEnd: (_) => Haptics.light(),
      // B5:休息區用 Reveal 展開 / 收合
      footer: resting.isEmpty
          ? null
          : Reveal(
              visible: showRest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child:
                        Text(s.restToday, style: theme.textTheme.titleMedium),
                  ),
                  for (final item in resting)
                    _row(
                      item,
                      HabitCard(
                        key: ValueKey('rest_${item.habit.id}'),
                        item: item,
                        resting: true,
                      ),
                      fresh,
                    ),
                ],
              ),
            ),
      itemCount: scheduled.length,
      onReorderItem: (o, n) {
        final order = scheduled.map((e) => e.habit.id!).toList();
        final moved = order.removeAt(o);
        order.insert(n, moved);
        ref.read(todayProvider.notifier).reorderVisible(order);
      },
      itemBuilder: (context, i) {
        final item = scheduled[i];
        return _row(
          item,
          HabitCard(key: ValueKey(item.habit.id), item: item),
          fresh,
        );
      },
    );
  }
}
