# Habit Tracker

極簡的待辦與習慣追蹤器,使用 Flutter 開發。資料全部存在本機,不需要帳號,也不需要網路。

## 功能

- **習慣打卡**:每天勾選完成,並以月曆檢視歷史紀錄
- **提醒通知**:可為每個習慣設定提醒時間
  - 點擊通知直接開啟該習慣的詳情頁
  - 重新開機後自動重排提醒
- **排序**:拖曳調整習慣順序
- **封存**:把不再進行的習慣封存,之後可還原
- **刪除確認與復原**:刪除前會確認,刪除後數秒內可按「復原」
- **JSON 備份與還原**
  - 匯出:存成 JSON 檔,可經分享選單傳到雲端或其他手機
  - 匯入:先驗證檔案,通過後才取代現有資料
- **外觀**:淺色、深色、跟隨系統
- **空狀態引導**:沒有習慣時顯示新增引導

## 技術

| 項目 | 使用 |
|---|---|
| 框架 | Flutter 3.47.7 / Dart 3.13.5 |
| 狀態管理 | Riverpod |
| 本機資料庫 | SQLite(`sqflite`) |
| 月曆 | `table_calendar` |
| 日期格式 | `intl` |
| 檔案選取 | `file_picker` |
| 分享 | `share_plus` |

資料表為 `habits` 與 `habit_logs`,資料庫版本 3。日期以 `YYYY-MM-DD` 字串儲存。

## 專案結構

```text
lib/
├── core/
│   └── date_utils.dart        日期工具
└── features/
    ├── habits/                習慣、打卡、通知
    │   └── presentation/
    └── settings/              設定、備份、封存
```

<!-- TODO: 若實際資料夾不同,請依 lib/ 內容修正 -->

## 開始使用

### 需求

- Flutter 3.47.7 以上
- Android 裝置或模擬器

### 執行

```bash
git clone https://github.com/powerkd/habit_tracker.git
cd habit_tracker
flutter pub get
flutter run
```

### 檢查

```bash
flutter analyze
flutter test
```

## Android 注意事項

- **通知權限**:Android 13 以上首次使用需允許通知。
- **提醒時間可能延遲**:提醒使用非精確排程,系統省電時可能晚幾分鐘。
- **部分手機(例如小米)**:請開啟「自啟動」,並把電池設定改成「無限制」,否則提醒可能不會觸發。

## 資料與備份

資料只存在手機本機。**解除安裝 App 會刪除所有資料。**
建議定期到「設定 → 匯出備份」存一份 JSON。

匯入備份會**取代**目前所有習慣與打卡紀錄。

## 簽署與發布

正式簽署用的 keystore 與 `android/key.properties` **不要提交到版本庫**。
更換 keystore 會導致使用者無法直接更新 App。

## 授權

MIT License

<!-- TODO: 根目錄尚未確認有 LICENSE 檔,請新增,否則這行沒有依據 -->