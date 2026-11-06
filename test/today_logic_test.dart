import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/habits/domain/today_logic.dart';

void main() {
  group('kMilestones', () {
    test('包含 7 / 30 / 100', () {
      expect(kMilestones, {7, 30, 100});
    });
  });

  group('MilestoneHit', () {
    test('相同內容視為相等', () {
      expect(const MilestoneHit(1, 7), const MilestoneHit(1, 7));
      expect(const MilestoneHit(1, 7).hashCode,
          const MilestoneHit(1, 7).hashCode);
    });

    test('內容不同則不相等', () {
      expect(const MilestoneHit(1, 7), isNot(const MilestoneHit(2, 7)));
      expect(const MilestoneHit(1, 7), isNot(const MilestoneHit(1, 30)));
    });

    test('toString 可讀', () {
      expect(const MilestoneHit(3, 7).toString(), 'MilestoneHit(3, 7)');
    });
  });

  group('findMilestone', () {
    test('連續天數 6 → 7 命中', () {
      final hit = findMilestone({1: 6}, {1: 7});
      expect(hit, const MilestoneHit(1, 7));
    });

    test('連續天數 29 → 30 命中', () {
      expect(findMilestone({1: 29}, {1: 30}), const MilestoneHit(1, 30));
    });

    test('連續天數 99 → 100 命中', () {
      expect(findMilestone({1: 99}, {1: 100}), const MilestoneHit(1, 100));
    });

    test('7 → 7(沒有增加)不命中', () {
      expect(findMilestone({1: 7}, {1: 7}), isNull);
    });

    test('連續天數減少不命中(例如取消打卡 7 → 6)', () {
      expect(findMilestone({1: 7}, {1: 6}), isNull);
    });

    test('增加但不是里程碑不命中', () {
      expect(findMilestone({1: 4}, {1: 5}), isNull);
      expect(findMilestone({1: 7}, {1: 8}), isNull);
    });

    test('跳過中間值但落在里程碑上,仍然命中', () {
      expect(findMilestone({1: 5}, {1: 7}), const MilestoneHit(1, 7));
    });

    test('新出現的習慣(before 沒有)不命中', () {
      expect(findMilestone({}, {1: 7}), isNull);
    });

    test('before 有、after 沒有(習慣被刪除)不命中', () {
      expect(findMilestone({1: 6}, {}), isNull);
    });

    test('兩邊都是空 Map 不命中', () {
      expect(findMilestone({}, {}), isNull);
    });

    test('多個習慣同時達標時,回傳 after 中的第一個', () {
      final hit = findMilestone(
        {1: 6, 2: 29},
        {1: 7, 2: 30},
      );
      expect(hit, const MilestoneHit(1, 7));
    });

    test('只有其中一個習慣達標時,回傳該習慣', () {
      final hit = findMilestone(
        {1: 3, 2: 29},
        {1: 4, 2: 30},
      );
      expect(hit, const MilestoneHit(2, 30));
    });
  });

  group('becameAllDone', () {
    test('[true,false] → [true,true] 回傳 true', () {
      expect(
        becameAllDone(before: [true, false], after: [true, true]),
        isTrue,
      );
    });

    test('全部 false → 全部 true 回傳 true', () {
      expect(
        becameAllDone(before: [false, false], after: [true, true]),
        isTrue,
      );
    });

    test('原本就全部完成,再次通知不會重複觸發', () {
      expect(
        becameAllDone(before: [true, true], after: [true, true]),
        isFalse,
      );
    });

    test('仍有未完成回傳 false', () {
      expect(
        becameAllDone(before: [false, false], after: [true, false]),
        isFalse,
      );
    });

    test('從全部完成變成有未完成(取消打卡)回傳 false', () {
      expect(
        becameAllDone(before: [true, true], after: [true, false]),
        isFalse,
      );
    });

    test('after 為空(今天沒有排程)回傳 false', () {
      expect(becameAllDone(before: [true], after: <bool>[]), isFalse);
      expect(becameAllDone(before: <bool>[], after: <bool>[]), isFalse);
    });

    test('before 為空、after 全部完成(新增並完成)回傳 true', () {
      expect(becameAllDone(before: <bool>[], after: [true]), isTrue);
    });

    test('新增一個未完成習慣,把「全部完成」打破,回傳 false', () {
      expect(
        becameAllDone(before: [true, true], after: [true, true, false]),
        isFalse,
      );
    });

    test('接受任何 Iterable(例如 map 的結果)', () {
      final before = [1, 2].map((e) => e > 5);
      final after = [6, 7].map((e) => e > 5);
      expect(becameAllDone(before: before, after: after), isTrue);
    });
  });

  group('splitByWeekday', () {
    // 假設每個項目是 (id, 有排程的星期集合)
    bool runsOn((int, Set<int>) item, int weekday) =>
        item.$2.contains(weekday);

    final everyDay = (1, {1, 2, 3, 4, 5, 6, 7});
    final weekdays = (2, {1, 2, 3, 4, 5});
    final weekend = (3, {6, 7});

    test('星期一:每天與平日在 scheduled,週末在 resting', () {
      final r = splitByWeekday([everyDay, weekdays, weekend], 1, runsOn);
      expect(r.scheduled.map((e) => e.$1), [1, 2]);
      expect(r.resting.map((e) => e.$1), [3]);
    });

    test('星期六:每天與週末在 scheduled,平日在 resting', () {
      final r = splitByWeekday([everyDay, weekdays, weekend], 6, runsOn);
      expect(r.scheduled.map((e) => e.$1), [1, 3]);
      expect(r.resting.map((e) => e.$1), [2]);
    });

    test('保持原本順序', () {
      final r = splitByWeekday([weekend, weekdays, everyDay], 7, runsOn);
      expect(r.scheduled.map((e) => e.$1), [3, 1]);
      expect(r.resting.map((e) => e.$1), [2]);
    });

    test('空清單回傳兩個空 List', () {
      final r = splitByWeekday<(int, Set<int>)>([], 1, runsOn);
      expect(r.scheduled, isEmpty);
      expect(r.resting, isEmpty);
    });

    test('全部都休息時 scheduled 為空', () {
      final r = splitByWeekday([weekend], 3, runsOn);
      expect(r.scheduled, isEmpty);
      expect(r.resting.map((e) => e.$1), [3]);
    });

    test('會把正確的 weekday 傳給 runsOn', () {
      final seen = <int>[];
      splitByWeekday<int>([1, 2], 4, (item, wd) {
        seen.add(wd);
        return true;
      });
      expect(seen, [4, 4]);
    });
  });

  group('celebratedKey', () {
    test('月份與日期補零', () {
      expect(celebratedKey(DateTime(2026, 1, 5)), 'celebrated_2026-01-05');
    });

    test('兩位數月份與日期不補零', () {
      expect(celebratedKey(DateTime(2026, 11, 17)), 'celebrated_2026-11-17');
    });

    test('忽略時分秒', () {
      expect(
        celebratedKey(DateTime(2026, 11, 7, 23, 59, 59)),
        'celebrated_2026-11-07',
      );
    });

    test('跨日後鍵不同', () {
      expect(
        celebratedKey(DateTime(2026, 11, 7, 23, 59)),
        isNot(celebratedKey(DateTime(2026, 11, 8, 0, 1))),
      );
    });
  });

  group('milestoneKey', () {
    test('格式為 milestone_<id>_<days>', () {
      expect(milestoneKey(3, 7), 'milestone_3_7');
      expect(milestoneKey(12, 100), 'milestone_12_100');
    });

    test('不同習慣或不同天數的鍵不同', () {
      expect(milestoneKey(1, 7), isNot(milestoneKey(2, 7)));
      expect(milestoneKey(1, 7), isNot(milestoneKey(1, 30)));
    });
  });
}
