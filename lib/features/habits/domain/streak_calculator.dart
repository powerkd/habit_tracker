import 'package:habit_tracker/core/date_utils.dart';


class StreakCalculator {
  /// 目前連續天數
  /// - 今天已完成：從今天往前算
  /// - 今天未完成但昨天完成：從昨天往前算
  /// - 否則為 0
  static int current(Set<String> completedKeys, DateTime today) {
    final todayDate = DateTime(today.year, today.month, today.day);
    var cursor = completedKeys.contains(toDateKey(todayDate))
        ? todayDate
        : addDays(todayDate, -1);

    var count = 0;
    while (completedKeys.contains(toDateKey(cursor))) {
      count++;
      cursor = addDays(cursor, -1);
    }
    return count;
  }

  /// 最長連續天數
  static int longest(Set<String> completedKeys) {
    if (completedKeys.isEmpty) return 0;

    final dates = completedKeys.map(DateTime.parse).toList()..sort();
    var best = 1;
    var run = 1;

    for (var i = 1; i < dates.length; i++) {
      if (addDays(dates[i - 1], 1) == dates[i]) {
        run++;
      } else {
        run = 1;
      }
      if (run > best) best = run;
    }
    return best;
  }
}
