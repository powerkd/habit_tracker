# 習慣追蹤 Habit Tracker

極簡的待辦／習慣追蹤器。沒有帳號、沒有廣告，資料只存在你的手機上。

A minimal habit tracker. No account, no ads. Your data stays on your phone.

## 功能 Features

**打卡**
- 每日目標 1～20 次，達到次數才算完成
- 每週排程：可只在指定星期執行，休息日有獨立顯示
- 補打卡：在日曆選過去日期補記或取消
- 連續天數、最長連續、累計完成
- 連續 7／30／100 天里程碑提示
- 全部完成慶祝動畫（每天一次）

**管理**
- 新增、編輯、封存、刪除（右滑刪除，可復原）
- 長按拖曳排序
- 每日提醒
- 備份匯出與匯入（JSON）
- Android 4×2 桌面小工具

**介面**
- iOS 風格設計：近黑背景、分組清單、浮動分頁列
- 淺色、深色、跟隨系統
- 8 種主題色
- 繁體中文與英文
- 動畫遵循系統「減少動畫」設定

**設定**
- 觸覺回饋、完成慶祝、里程碑提示可分別開關
- 每週起始日（週一／週日）
- 顯示或隱藏休息日習慣
- 說明、回報問題、複製診斷資訊、關於

## 資料與隱私 Data & privacy

- 資料存在手機本機的 SQLite，**沒有雲端同步**。
- **解除安裝 App 會一併刪除資料。** 換手機或重裝前，請到「設定 → 匯出備份」存檔。
- 習慣名稱由你輸入，不會自動翻譯。
- 「複製診斷資訊」只包含 App 版本、系統版本與語言，不含習慣資料。

## 技術 Tech stack

| 項目 | 使用 |
|---|---|
| 框架 | Flutter（Dart 3） |
| 狀態管理 | Riverpod |
| 本機資料庫 | sqflite |
| 日曆 | table_calendar |
| 多語系 | intl、flutter_localizations |
| 桌面小工具 | home_widget |
| 備份 | file_picker、share_plus |
| 其他 | url_launcher、package_info_plus |
| 字型 | Inter（英文與數字），中文使用系統字型 |

## 專案結構 Structure

```
lib/
├── app/                 App 入口與主題套用
├── core/                共用元件：主題、動畫、字串、觸覺、導覽
└── features/
    ├── habits/          習慣：資料、領域邏輯、介面
    └── settings/        設定、說明、關於、備份
```

<!-- TODO: 對照實際目錄，修正上面的結構 -->

## 開發 Development

需求：Flutter stable、Android SDK。

```bash
git clone https://github.com/powerkd/habit_tracker.git
cd habit_tracker
flutter pub get
flutter run
```

檢查：

```bash
flutter analyze
flutter test
```

## 建置 Build

```bash
flutter build apk --release
```

輸出位置：`build/app/outputs/flutter-apk/app-release.apk`

### 簽章

正式版需要自己的簽章金鑰。請建立 `android/key.properties` 並指定你的 keystore。

**`key.properties`、`.jks`、`.keystore` 不可提交到版本庫。** 已列入 `.gitignore`。

<!-- TODO: 確認 .gitignore 有這三項 -->

## 安裝注意 Install notes

小米／Redmi（MIUI／HyperOS）從 USB 安裝可能出現
`INSTALL_FAILED_USER_RESTRICTED`。
請到「開發人員選項」開啟「透過 USB 安裝」，並在手機上允許安裝。

簽章與舊版不同時無法覆蓋安裝。**解除安裝前請先匯出備份**，否則資料會消失。

## 字型授權 Font license

英文與數字使用 [Inter](https://rsms.me/inter/)，採用 SIL Open Font License 1.1。

## 授權 License

<!-- TODO: 填入實際授權，若尚未選擇請先加 LICENSE 檔 -->

## 更新紀錄 Changelog

見 [Releases](https://github.com/powerkd/habit_tracker/releases)。
