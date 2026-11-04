import 'package:flutter/material.dart';
import '../features/habits/domain/weekday_utils.dart';

class S {
  final bool zh;
  const S._(this.zh);
  static S of(BuildContext c) =>
      S._(Localizations.localeOf(c).languageCode == 'zh');

  String _t(String z, String e) => zh ? z : e;

  // 通用
  String get cancel => _t('取消', 'Cancel');
  String get undo => _t('復原', 'Undo');

  // 今天頁
  String get today => _t('今天', 'Today');
  String get restToday => _t('今天休息', 'Rest today');
  String get noScheduled => _t('沒有排程的習慣', 'Nothing scheduled');
  String get settings => _t('設定', 'Settings');
  String get allDoneTitle => _t('今天全部完成！', 'All done today!');
  String get celebrate => _t('慶祝', 'Celebration');
  String loadFailed(Object e) => _t('載入失敗：$e', 'Failed to load: $e');
  String progressLabel(int d, int t) =>
      _t('今日進度 $d／$t', 'Today’s progress $d of $t');
  String doneOf(int d, int t) => _t('已完成 $d／$t', '$d of $t done');
  String get allDoneEmoji => _t('今天全部完成 🎉', 'All done today 🎉');
  String remaining(int n) => _t('還差 $n 個', '$n to go');
  String get noHabits => _t('還沒有任何習慣', 'No habits yet');
  String get noHabitsSub => _t(
      '從一個小習慣開始,\n每天打卡,累積連續天數。',
      'Start with one small habit,\ncheck in daily and build a streak.');
  String get addFirst => _t('新增第一個習慣', 'Add your first habit');
  String get addHabit => _t('新增習慣', 'Add habit');
  String get uncheck => _t('取消完成', 'Mark as not done');
  String get check => _t('標記完成', 'Mark as done');
  String get decrease => _t('減少一次', 'Remove one');
  String get targetReached => _t('今天已達標', 'Target reached today');
  String tapOnce(int c, int t) =>
      _t('完成一次，目前 $c／$t', 'Add one, now $c of $t');
  String get completed => _t('已完成', 'Done');
  String get notDone => _t('未完成', 'Not done');
  String streak(int n) =>
      _t('🔥 $n 天', '🔥 $n ${n == 1 ? 'day' : 'days'}');
  String deleted(String name) => _t('已刪除「$name」', 'Deleted “$name”');
  String deleteFailed(Object e) => _t('刪除失敗：$e', 'Delete failed: $e');

  // 設定頁
  String get appearance => _t('外觀', 'Appearance');
  String get system => _t('系統', 'System');
  String get light => _t('淺色', 'Light');
  String get dark => _t('深色', 'Dark');
  String get language => _t('語言', 'Language');
  String get data => _t('資料', 'Data');
  String get archived => _t('已封存的習慣', 'Archived habits');
  String get export => _t('匯出備份', 'Export backup');
  String get exportSub => _t('存成 JSON 檔,可傳到雲端或其他手機',
      'Save as a JSON file to share or move to another phone');
  String get import => _t('匯入備份', 'Import backup');
  String get importSub => _t('從 JSON 檔還原(會取代目前資料)',
      'Restore from a JSON file (replaces current data)');
  String get backupSubject => _t('Habit Tracker 備份', 'Habit Tracker backup');
  String exportFailed(Object e) => _t('匯出失敗:$e', 'Export failed: $e');
  String get importWarn => _t('這會取代目前所有習慣與打卡紀錄,確定要繼續嗎?',
      'This replaces all current habits and check-ins. Continue?');
  String get pickFile => _t('選擇檔案', 'Choose file');
  String importDone(int h, int l) => _t('匯入完成:$h 個習慣、$l 筆打卡紀錄',
      'Imported $h habits and $l check-ins');
  String importFailed(Object e) => _t('匯入失敗:$e', 'Import failed: $e');

  // 桌面小工具
  String get homeScreen => _t('桌面', 'Home screen');
  String get addWidget => _t('加入桌面小工具', 'Add home screen widget');
  String get addWidgetSub =>
      _t('在桌面顯示今日進度', 'Show today’s progress on your home screen');
  String get pinTitle => _t('手動加入小工具', 'Add the widget manually');
  String get pinBody => _t(
      '長按桌面空白處 → 小工具 → 找到 habit_tracker → 拖到桌面。',
      'Long-press the home screen → Widgets → find habit_tracker → drag it onto the home screen.');
  String get ok => _t('知道了', 'OK');

    // ── 星期 ──
  static const _wdZh = ['一', '二', '三', '四', '五', '六', '日'];
  static const _wdEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// i = 0..6，0 代表週一
  String weekdayShort(int i) => zh ? _wdZh[i] : _wdEn[i];

  String scheduleLabel(int mask) {
    if (mask == allWeekdays) return _t('每天', 'Every day');
    if (mask == workdays) return _t('平日', 'Weekdays');
    if (mask == weekend) return _t('週末', 'Weekends');
    final names = [
      for (var i = 0; i < 7; i++)
        if (weekdayRuns(mask, i + 1)) weekdayShort(i),
    ];
    return zh ? '週${names.join('、')}' : names.join(', ');
  }

  // ── 表單頁 ──
  String get editHabit => _t('編輯習慣', 'Edit habit');
  String get newHabit => _t('新增習慣', 'New habit');
  String get basicInfo => _t('基本資料', 'Basics');
  String get habitName => _t('習慣名稱', 'Habit name');
  String get habitNameHint => _t('例如：閱讀 15 分鐘', 'e.g. Read for 15 minutes');
  String get descOptional => _t('說明（選填）', 'Description (optional)');
  String get nameRequired => _t('請輸入習慣名稱', 'Please enter a name');
  String get iconLabel => _t('圖示', 'Icon');
  String get colorLabel => _t('顏色', 'Color');
  String get dailyTimes => _t('每日次數', 'Daily count');
  String get timesPerDay => _t('每天要做幾次', 'Times per day');
  String get tapOnceDone => _t('點一下就完成', 'One tap to complete');
  String doneAfter(int n) => _t('做滿 $n 次才算完成', 'Complete after $n times');
  String get decreaseTimes => _t('減少次數', 'Decrease');
  String get increaseTimes => _t('增加次數', 'Increase');
  String dailyTimesSemantic(int n) => _t('每日次數 $n', 'Daily count $n');
  String get raiseWarn => _t(
      '提高次數後，過去次數不足的日子會變成未完成，連續天數可能下降。',
      'Raising the count turns past days that fall short into incomplete, so your streak may drop.');
  String get repeatAndRemind => _t('重複與提醒', 'Repeat & reminder');
  String get repeat => _t('重複', 'Repeat');
  String get everyDay => _t('每天', 'Every day');
  String get weekdaysChip => _t('平日', 'Weekdays');
  String get weekendChip => _t('週末', 'Weekends');
  String get pickAtLeastOne => _t('至少選擇一天', 'Pick at least one day');
  String get reminder => _t('提醒', 'Reminder');
  String get notSet => _t('未設定', 'Not set');
  String get tapPickTime => _t('點一下選擇時間', 'Tap to pick a time');
  String get clearReminder => _t('清除提醒', 'Clear reminder');
  String get save => _t('儲存', 'Save');
  String get saving => _t('儲存中…', 'Saving…');
  String saveFailed(Object e) => _t('儲存失敗：$e', 'Save failed: $e');

  // ── 詳情頁 ──
  String get archiveTitle => _t('封存習慣', 'Archive habit');
  String archiveBody(String n) => _t(
      '「$n」將從今日清單移除，歷史紀錄會保留。',
      '“$n” will be removed from today’s list. History is kept.');
  String get archiveBtn => _t('封存', 'Archive');
  String get edit => _t('編輯', 'Edit');
  String counterSemantic(String label, int c, int t) =>
      _t('$label，已完成 $c 次，目標 $t 次', '$label, done $c times, target $t');
  String get reached => _t('已達標', 'Target reached');
  String get doOnce => _t('完成一次', 'Add one');
  String get todayRestDay => _t('今天（休息日）', 'Today (rest day)');
  String targetPerDay(int n) => _t('🎯 每天 $n 次', '🎯 $n times a day');
  String remindAt(String t) => _t('⏰ $t 提醒', '⏰ Reminder at $t');
  String get currentStreakLabel => _t('目前連續', 'Current streak');
  String get longestStreakLabel => _t('最長連續', 'Longest streak');
  String get totalDoneLabel => _t('總完成', 'Total done');
  String daysValue(int n) => _t('$n 天', '$n ${n == 1 ? 'day' : 'days'}');
  String timesValue(int n) => _t('$n 次', '$n');
  String get cancelToday => _t('取消今日完成', 'Undo today');
  String get completeToday => _t('完成今日', 'Complete today');
  String get restDayStillCheck =>
      _t('今天休息，仍要打卡', 'Rest day — check in anyway');
  String get monthFormat => _t('月', 'Month');
  String dayStatus({
    required String key,
    required bool done,
    required bool multi,
    required int count,
    required int target,
    required bool scheduled,
  }) {
    final state = done
        ? _t('✅ 已完成', '✅ Done')
        : (multi && count > 0
            ? _t('進行中', 'In progress')
            : _t('尚未完成', 'Not done'));
    final cnt = multi ? (zh ? '（$count/$target）' : ' ($count/$target)') : '';
    final off = scheduled ? '' : _t('（非排程日）', ' (not scheduled)');
    return '$key${zh ? '：' : ': '}$state$cnt$off';
  }

  String get cancelThatDay => _t('取消這天的完成', 'Undo this day');
  String get makeUp => _t('補打這天', 'Check in for this day');

  // ── 已封存頁 ──
  String get permDelete => _t('永久刪除', 'Delete permanently');
  String permDeleteBody(String n) => _t(
      '「$n」與所有打卡紀錄都會被刪除。\n刪除後 6 秒內可以復原。',
      '“$n” and all check-ins will be deleted.\nYou can undo within 6 seconds.');
  String get delete => _t('刪除', 'Delete');
  String restoreFailed(Object e) => _t('復原失敗:$e', 'Undo failed: $e');
  String get noArchived => _t('沒有已封存的習慣', 'No archived habits');
  String startedOn(String d) => _t('開始於 $d', 'Started $d');
  String get restore => _t('還原', 'Restore');

}
