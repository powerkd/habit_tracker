# Habit Tracker

極簡的習慣追蹤器,使用 Flutter 開發。資料只存在你的手機裡,沒有帳號、沒有雲端、沒有廣告。

[English](#english) · [回報問題](https://github.com/powerkd/habit_tracker/issues)

## 功能

- **每週排程**:每個習慣可自訂重複的星期,休息日不會中斷連續天數
- **每日目標**:每天 1 到 20 次,達到才算完成
- **提醒**:本機通知,依排程日提醒
- **補打卡**:在日曆選擇過去的日期補上紀錄
- **連續天數**:火焰徽章與里程碑提示
- **完成慶祝**:當天全部完成時顯示彩帶動畫
- **封存**:保留歷史紀錄但不再顯示
- **備份與還原**:匯出 JSON 檔,換手機時匯入
- **Android 小工具**:4×2 桌面小工具
- **外觀**:淺色、深色、跟隨系統,可選主題色
- **語言**:繁體中文、English

### 操作

| 動作 | 效果 |
|---|---|
| 點卡片 | 打卡 |
| 長按拖曳 | 調整順序 |
| 向右滑 | 刪除,頂部可復原 |
| 進入詳情頁 | 查看日曆、補打卡、編輯 |

## 隱私

- 所有資料存在本機 SQLite,不上傳任何伺服器
- 沒有分析工具與追蹤
- 解除安裝 App 會一併刪除資料,請定期到「設定」匯出備份
- 「複製診斷資訊」只包含版本、系統與語言,不含任何習慣資料

## 安裝

到 [Releases](https://github.com/powerkd/habit_tracker/releases) 下載最新的 APK 安裝。

Android 會要求允許安裝未知來源的應用程式。小米、Redmi 等裝置若 USB 安裝失敗並出現 `INSTALL_FAILED_USER_RESTRICTED`,請到開發者選項開啟「USB 安裝」。

## 從原始碼建置

需求:Flutter 3.47 以上(Dart 3.13)。

```bash
git clone https://github.com/powerkd/habit_tracker.git
cd habit_tracker
flutter pub get
flutter run
```

### 產生圖示

```bash
dart run flutter_launcher_icons
```

圖示來源路徑在 `pubspec.yaml` 的 `flutter_launcher_icons` 區塊設定。

### 打包 Release APK

```bash
flutter build apk --release
```

輸出在 `build/app/outputs/flutter-apk/app-release.apk`。

簽署用的 `key.properties`、`.jks`、`.keystore` **不要提交**,請確認已列入 `.gitignore`。

### 檢查與測試

```bash
flutter analyze
flutter test
```

## 技術

| 項目 | 使用 |
|---|---|
| 狀態管理 | Riverpod |
| 本機儲存 | sqflite、shared_preferences |
| 日曆 | table_calendar |
| 通知 | flutter_local_notifications |
| 桌面小工具 | home_widget |
| 備份 | file_picker、share_plus |
| 字型 | Inter(英文與數字),中文使用系統字型 |

日期以 `YYYY-MM-DD` 字串儲存,日期工具在 `lib/core/date_utils.dart`。

## 專案結構

```text
lib/
  core/          主題、元件、Toast、轉場、字串、共用工具
  features/
    habits/      今天頁、習慣詳情、新增與編輯
    settings/    設定、說明、封存、關於、備份
test/            單元測試
```

## 參與

發現問題或有建議,請到 [Issues](https://github.com/powerkd/habit_tracker/issues) 回報。回報時可附上設定頁的「複製診斷資訊」。

## 授權

請在此填入授權(例如 MIT),並在專案根目錄加入 `LICENSE` 檔。

Inter 字型採用 SIL Open Font License 1.1,版權屬於 The Inter Project Authors。

---

## English

A minimal habit tracker built with Flutter. Your data stays on your phone: no account, no cloud, no ads.

### Features

- Weekly schedules with rest days that never break your streak
- Daily targets from 1 to 20 completions
- Local reminders
- Make up missed days from the calendar
- Streak flame badge and milestones
- Confetti when everything is done for the day
- Archive habits without losing history
- JSON backup and restore
- Android 4×2 home screen widget
- Light, dark, and system themes with selectable accent colors
- Traditional Chinese and English

### Privacy

All data is stored in a local SQLite database. Nothing is uploaded, and there is no analytics. Uninstalling the app deletes your data, so export a backup from Settings regularly.

### Install

Download the latest APK from [Releases](https://github.com/powerkd/habit_tracker/releases).

### Build from source

Requires Flutter 3.47 or later (Dart 3.13).

```bash
git clone https://github.com/powerkd/habit_tracker.git
cd habit_tracker
flutter pub get
flutter run
```

### License

Add your license here. Inter is licensed under the SIL Open Font License 1.1.
