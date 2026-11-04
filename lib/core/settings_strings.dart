import 'strings.dart';

/// 設定頁新增的字串,放在獨立檔案,不動 strings.dart
extension SettingsStrings on S {
  String _x(String z, String e) => zh ? z : e;

  String get feedbackSection => _x('打卡體驗', 'Check-ins');
  String get hapticsTitle => _x('觸覺回饋', 'Haptic feedback');
  String get hapticsSub => _x('打卡、切換時震動', 'Vibrate on actions');
  String get celebrateTitle => _x('完成慶祝', 'Completion celebration');
  String get celebrateSub =>
      _x('全部完成時顯示彈窗', 'Show a popup when all done');
  String get milestoneTitle => _x('里程碑提示', 'Milestone alerts');
  String get milestoneSub =>
      _x('連續 7／30／100 天時提示', 'At 7, 30 and 100-day streaks');

  String get displaySection => _x('顯示', 'Display');
  String get weekStartTitle => _x('每週起始日', 'Week starts on');
  String get monday => _x('週一', 'Monday');
  String get sunday => _x('週日', 'Sunday');
  String get showRestTitle => _x('顯示休息日習慣', 'Show rest-day habits');
  String get showRestSub =>
      _x('今天頁底部的「今天休息」區', 'The “Rest today” list');

  String get accentTitle => _x('主題色', 'Accent color');
  String get dataNote => _x(
      '資料只存在這支手機上，沒有雲端同步。解除安裝 App 會一併刪除資料，請定期匯出備份。',
      'Your data is stored only on this device, with no cloud sync. '
          'Uninstalling the app deletes it, so export backups regularly.');

  // 說明 / 支援 / 關於
  String get helpSupportSection => _x('說明與支援', 'Help & Support');
  String get helpRowTitle => _x('說明', 'Help');
  String get helpRowSub => _x('常見問題與使用方式', 'FAQ and how-tos');
  String get supportRowTitle => _x('回報問題', 'Report an issue');
  String get supportRowSub =>
      _x('在 GitHub 開啟 Issue', 'Open an issue on GitHub');
  String get diagRowTitle => _x('複製診斷資訊', 'Copy diagnostic info');
  String get diagRowSub =>
      _x('版本與系統資訊,回報問題時附上', 'Version and OS info for bug reports');
  String get diagCopied => _x('已複製診斷資訊', 'Diagnostic info copied');
  String get aboutRowTitle => _x('關於', 'About');
  String get openLinkFailed => _x('無法開啟連結', 'Couldn’t open the link');

  String get helpPageTitle => _x('說明', 'Help');
  String get aboutPageTitle => _x('關於', 'About');
  String get versionLabel => _x('版本', 'Version');
  String get sourceCodeRow => _x('原始碼', 'Source code');
  String get aboutBlurb => _x(
      '極簡的習慣追蹤器。沒有帳號、沒有廣告，資料只存在你的手機上。',
      'A minimal habit tracker. No account, no ads. '
          'Your data stays on your phone.');

  /// 常見問題:每項為 (問題, 答案)
  List<(String, String)> get faqs => [
        (
          _x('如何新增習慣？', 'How do I add a habit?'),
          _x('在「今天」分頁點右下角的 ＋，輸入名稱、選圖示和顏色後儲存。',
              'On the Today tab, tap ＋ at the bottom right, enter a name, '
                  'pick an icon and color, then save.'),
        ),
        (
          _x('一天要做很多次怎麼辦？', 'What if I do it several times a day?'),
          _x('編輯習慣時設定「每日次數」（1～20 次）。達到次數才算當天完成。',
              'Set “times per day” (1–20) when editing a habit. '
                  'It counts as done once you reach the target.'),
        ),
        (
          _x('忘記打卡，可以補嗎？', 'I forgot to check in. Can I fix it?'),
          _x('進入習慣詳情，在日曆選過去的日期，再點「補打卡」。未來的日期不能選。',
              'Open the habit, pick a past date on the calendar, '
                  'then tap “Make up”. Future dates can’t be selected.'),
        ),
        (
          _x('怎麼刪除或封存習慣？', 'How do I delete or archive a habit?'),
          _x('在「今天」分頁把習慣向右滑可刪除，刪除後可按「復原」。封存請到習慣詳情右上角；'
              '封存的習慣可在 設定 → 已封存 查看。',
              'Swipe a habit right on Today to delete it; tap Undo to bring it '
                  'back. To archive, use the button at the top right of the '
                  'habit page. Archived habits are under Settings → Archived.'),
        ),
        (
          _x('資料會不會不見？', 'Could I lose my data?'),
          _x('資料只存在這支手機，沒有雲端同步。解除安裝 App 或換手機前，'
              '請到 設定 → 匯出備份 儲存檔案，之後可用「匯入備份」還原。',
              'Data lives only on this phone, with no cloud sync. Before '
                  'uninstalling or switching phones, use Settings → Export '
                  'backup, and restore later with Import backup.'),
        ),
        (
          _x('提醒沒有響？', 'My reminder didn’t fire.'),
          _x('請確認已允許通知權限，並在系統設定中關閉本 App 的電池最佳化。'
              '部分手機（如小米、OPPO）還需要開啟「自啟動」。',
              'Make sure notifications are allowed and battery optimization '
                  'is off for this app. Some phones (Xiaomi, OPPO) also need '
                  '“Autostart” enabled.'),
        ),
        (
          _x('怎麼加入桌面小工具？', 'How do I add the home-screen widget?'),
          _x('Android 限定。到 設定 → 主畫面 → 新增小工具，或長按桌面從小工具清單加入。',
              'Android only. Go to Settings → Home screen → Add widget, '
                  'or long-press your home screen and pick it from the list.'),
        ),
      ];
}
