# Habit Tracker

極簡待辦與習慣追蹤器。每天打卡、累積連續天數，支援每週排程與提醒。介面採用 Liquid Glass 風格，支援淺色與深色模式。

## 功能

- **每日打卡**：點一下完成，再點一下取消
- **每週排程**：每個習慣可選擇週一到週日要執行的日子
- **今天休息**：非排程日的習慣會移到獨立區塊
- **連續天數**：依排程計算 streak
- **補打卡**：在詳情頁或日曆補記過去的日期
- **提醒通知**：依所選星期觸發
- **拖曳排序**：長按卡片調整順序
- **日曆檢視**：查看每天的完成紀錄
- **封存**：不再執行的習慣可封存
- **備份與還原**：匯出與匯入資料，舊版備份會視為每天執行
- **淺色與深色模式**，支援系統動態字級

## 技術

| 項目 | 使用 |
|---|---|
| 框架 | Flutter 3.47.7、Dart 3.13.5 |
| 狀態管理 | Riverpod |
| 本機資料庫 | SQLite（`sqflite`） |
| 日曆 | `table_calendar` |
| 日期格式 | `intl` |

## 專案結構

```text
lib/
├── app/                   # App 入口、主題、路由
├── core/                  # 共用工具與元件
│   ├── date_utils.dart    # 日期鍵 YYYY-MM-DD
│   ├── glass_kit.dart     # 玻璃風格元件
│   └── progress_ring.dart
└── features/
    ├── habits/            # 習慣、今日頁、詳情、表單
    └── settings/          # 設定、備份
```

## 資料儲存

- 資料只存在手機本機的 SQLite，**沒有雲端同步**。
- 解除安裝 App 會刪除資料，換手機前請先匯出備份。
- 星期排程以 bitmask 存在 `habits.weekdays`（週一為最低位元），`127` 代表每天。
- 目前資料庫版本為 v4。

## 開發

需求：Flutter 3.47.7 以上。

```bash
git clone https://github.com/powerkd/habit_tracker.git
cd habit_tracker
flutter pub get
flutter run
```

檢查與測試：

```bash
flutter analyze
flutter test
```

效能測試請在實體手機使用 profile 模式：

```bash
flutter run --profile
```

## 打包 Android

```bash
flutter build apk --release
flutter build appbundle --release
```

簽章需要 `android/key.properties` 與 keystore。這些檔案**不可提交**到 Git。

## 隱私

App 不蒐集、不上傳任何資料。所有紀錄都留在你的裝置上。

## 授權

尚未指定授權。如要開源，請加入 `LICENSE` 檔並更新此段。