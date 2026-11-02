import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/habits/domain/streak_calculator.dart';

void main() {
  group('current streak', () {
    test('沒有紀錄回傳 0', () {
      expect(StreakCalculator.current({}, DateTime(2026, 11, 3)), 0);
    });

    test('今天已完成，連續 3 天', () {
      final keys = {'2026-11-01', '2026-11-02', '2026-11-03'};
      expect(StreakCalculator.current(keys, DateTime(2026, 11, 3)), 3);
    });

    test('今天未完成但昨天完成，不歸零', () {
      final keys = {'2026-11-01', '2026-11-02', '2026-11-03'};
      expect(StreakCalculator.current(keys, DateTime(2026, 11, 4)), 3);
    });

    test('今天與昨天都未完成，歸零', () {
      final keys = {'2026-11-01', '2026-11-02', '2026-11-03'};
      expect(StreakCalculator.current(keys, DateTime(2026, 11, 5)), 0);
    });

    test('中間漏一天只計算最近一段', () {
      final keys = {'2026-11-01', '2026-11-03'};
      expect(StreakCalculator.current(keys, DateTime(2026, 11, 3)), 1);
    });

    test('跨年可正常計算', () {
      final keys = {'2026-12-31', '2027-01-01'};
      expect(StreakCalculator.current(keys, DateTime(2027, 1, 1)), 2);
    });
  });

  group('longest streak', () {
    test('沒有紀錄回傳 0', () {
      expect(StreakCalculator.longest({}), 0);
    });

    test('找出最長的一段', () {
      final keys = {
        '2026-11-01', '2026-11-02',
        '2026-11-05', '2026-11-06', '2026-11-07',
      };
      expect(StreakCalculator.longest(keys), 3);
    });

    test('閏年 2 月可正常計算', () {
      final keys = {'2028-02-28', '2028-02-29', '2028-03-01'};
      expect(StreakCalculator.longest(keys), 3);
    });
  });
}
