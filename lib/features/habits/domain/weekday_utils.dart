const weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

const allWeekdays = 127; // 週一~週日
const workdays = 31; // 週一~週五
const weekend = 96; // 週六、週日

/// weekday:DateTime.weekday(1=週一 … 7=週日)
bool weekdayRuns(int mask, int weekday) => (mask >> (weekday - 1)) & 1 == 1;

String weekdaysLabel(int mask) {
  if (mask == allWeekdays) return '每天';
  if (mask == workdays) return '平日';
  if (mask == weekend) return '週末';
  final days = [
    for (var i = 0; i < 7; i++)
      if ((mask >> i) & 1 == 1) '週${weekdayNames[i]}'
  ];
  return days.join('、');
}
