/// 日期轉 當地日期 ex: 2026-11-01
String toDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime fromDatekey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

DateTime addDays(DateTime date, int days) =>
  DateTime(date.year, date.month, date.day + days);