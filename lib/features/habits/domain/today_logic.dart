// 今天頁面的純邏輯。不依賴 Flutter / Riverpod,可直接單元測試。

/// 會觸發提示的連續天數
const Set<int> kMilestones = {7, 30, 100};

class MilestoneHit {
  final int habitId;
  final int days;
  const MilestoneHit(this.habitId, this.days);

  @override
  bool operator ==(Object other) =>
      other is MilestoneHit && other.habitId == habitId && other.days == days;

  @override
  int get hashCode => Object.hash(habitId, days);

  @override
  String toString() => 'MilestoneHit($habitId, $days)';
}

/// 比較前後的連續天數(habitId -> streak),
/// 找出第一個「增加並剛好達到里程碑」的習慣;沒有則回傳 null。
MilestoneHit? findMilestone(
  Map<int, int> before,
  Map<int, int> after,
) {
  for (final e in after.entries) {
    final prev = before[e.key];
    if (prev == null) continue;
    if (e.value > prev && kMilestones.contains(e.value)) {
      return MilestoneHit(e.key, e.value);
    }
  }
  return null;
}

/// 連續天數的外觀等級:
/// 0 = 無、1 = 1~6 天、2 = 7~29 天、3 = 30~99 天、4 = 100 天以上
int streakTier(int days) {
  if (days >= 100) return 4;
  if (days >= 30) return 3;
  if (days >= 7) return 2;
  if (days >= 1) return 1;
  return 0;
}

/// 是否「剛好」從未全部完成變成全部完成。
/// [before] / [after] 為今日排程習慣的完成狀態。
bool becameAllDone({
  required Iterable<bool> before,
  required Iterable<bool> after,
}) {
  final b = before.toList();
  final a = after.toList();
  if (a.isEmpty) return false;
  final wasAll = b.isNotEmpty && b.every((e) => e);
  final nowAll = a.every((e) => e);
  return !wasAll && nowAll;
}

/// 依星期把習慣分成「今天要做」與「今天休息」。
({List<T> scheduled, List<T> resting}) splitByWeekday<T>(
  Iterable<T> items,
  int weekday,
  bool Function(T item, int weekday) runsOn,
) {
  final scheduled = <T>[];
  final resting = <T>[];
  for (final i in items) {
    (runsOn(i, weekday) ? scheduled : resting).add(i);
  }
  return (scheduled: scheduled, resting: resting);
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 每日慶祝的 prefs 鍵,例如 celebrated_2026-11-07
String celebratedKey(DateTime d) =>
    'celebrated_${d.year}-${_two(d.month)}-${_two(d.day)}';

/// 里程碑的 prefs 鍵,例如 milestone_3_7
String milestoneKey(int habitId, int days) => 'milestone_${habitId}_$days';
