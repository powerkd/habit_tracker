import 'package:habit_tracker/core/date_utils.dart';

class StreakCalculator {
  static bool _runs(int weekdays, DateTime d) =>
      (weekdays & (1 << (d.weekday - 1))) != 0;

  /// 目前連續天數
  ///
  /// - 非排程日:沒打卡不中斷,有打卡則計入
  /// - 排程日:沒打卡就中斷
  /// - 今天是排程日但還沒打卡:不算中斷,從昨天往前算
  static int current(Set<String> completedKeys, DateTime today,
      {int weekdays = 127}) {
    if (weekdays & 127 == 0) return 0;

    final todayDate = DateTime(today.year, today.month, today.day);
    var cursor = todayDate;
    var count = 0;

    // 往前最多掃描 10 年,避免異常資料造成無窮迴圈
    for (var i = 0; i < 3660; i++) {
      final done = completedKeys.contains(toDateKey(cursor));
      final scheduled = _runs(weekdays, cursor);
      final isToday = cursor == todayDate;

      if (done) {
        count++;
      } else if (scheduled && !isToday) {
        break; // 過去的排程日沒做,中斷
      }
      // 其餘情況:今天尚未完成、或非排程日未打卡 → 略過
      cursor = addDays(cursor, -1);
    }
    return count;
  }

  /// 最長連續天數
  static int longest(Set<String> completedKeys, {int weekdays = 127}) {
    if (completedKeys.isEmpty) return 0;
    if (weekdays & 127 == 0) return 0;

    final dates = completedKeys.map(DateTime.parse).toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;

    for (final d in dates) {
      if (prev == null) {
        run = 1;
      } else {
        // prev 與 d 之間的日子,只要有任何一天是排程日就中斷
        var missed = false;
        var c = addDays(prev, 1);
        while (c.isBefore(d)) {
          if (_runs(weekdays, c)) {
            missed = true;
            break;
          }
          c = addDays(c, 1);
        }
        run = missed ? 1 : run + 1;
      }
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }
}