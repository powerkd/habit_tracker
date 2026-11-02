import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// 全部完成時的慶祝動畫
  Future<void> _celebrate() async {
    HapticFeedback.heavyImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '慶祝',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, _) {
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 64)),
                    SizedBox(height: 8),
                    Text('今天全部完成！',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(todayProvider);

    // 只在「從未全部完成」變成「全部完成」的那一刻觸發
    ref.listen(todayProvider, (prev, next) {
      final before = prev?.value;
      final after = next.value;
      if (before == null || after == null || after.isEmpty) return;
      final wasAll = before.isNotEmpty && before.every((e) => e.doneToday);
      final nowAll = after.every((e) => e.doneToday);
      if (!wasAll && nowAll) _celebrate();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(dateText),
        actions: [
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
        data: (items) {
          if (items.isEmpty) {
            final theme = Theme.of(context);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.checklist_rounded,
                        size: 72,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5)),
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
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HabitFormPage()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('新增第一個習慣'),
                    ),
                  ],
                ),
              ),
            );
          }
          final done = items.where((i) => i.doneToday).length;
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            header: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('已完成 $done／${items.length}',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            itemCount: items.length,
            onReorderItem: (o, n) =>
                ref.read(todayProvider.notifier).reorder(o, n),
            itemBuilder: (context, i) {
              final item = items[i];
              return _HabitCard(
                key: ValueKey(item.habit.id),
                item: item,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HabitFormPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('新增習慣'),
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final HabitItem item;
  const _HabitCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(item.habit.colorValue);
    final done = item.doneToday;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: done ? color.withValues(alpha: 0.15) : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? color : scheme.outlineVariant),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HabitDetailPage(habitId: item.habit.id!),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(iconFor(item.habit.iconKey), color: color),
        ),
        title: Text(item.habit.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '🔥 連續 ${item.currentStreak} 天 · ${done ? "已完成" : "未完成"}'),
        trailing: IconButton(
          tooltip: done ? '取消完成' : '標記完成',
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              key: ValueKey(done),
              color: done ? color : Colors.grey,
              size: 32,
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
    );
  }
}
