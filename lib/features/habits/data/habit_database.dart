import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HabitDatabase {
  static Future<Database>? _opening;

  /// 快取 Future:多處同時第一次呼叫也只會開啟一次
  static Future<Database> get instance => _opening ??= _open().catchError((e) {
        _opening = null; // 開啟失敗時允許重試
        throw e;
      });

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'habit_tracker.db');

    return openDatabase(
      path,
      version: 6,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        // WAL:寫入不會擋住讀取。失敗就用預設模式,不影響功能
        try {
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.execute('PRAGMA synchronous = NORMAL');
        } catch (_) {}
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            icon_key TEXT NOT NULL,
            color_value INTEGER NOT NULL,
            start_date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            is_archived INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0,
            remind_time TEXT,
            weekdays INTEGER NOT NULL DEFAULT 127,
            daily_target INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE habit_logs (
            habit_id INTEGER NOT NULL,
            date_key TEXT NOT NULL,
            completed_at TEXT NOT NULL,
            count INTEGER NOT NULL DEFAULT 1,
            PRIMARY KEY (habit_id, date_key),
            FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
          )
        ''');
        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureColumns(db);
        // v6:新增索引(只新增,不動既有資料)
        await _createIndexes(db);
      },
      // 保險:即使版本號已是最新但欄位缺失,也會在開啟時補上
      onOpen: (db) async {
        await _ensureColumns(db);
      },
    );
  }

  /// 全部用 IF NOT EXISTS,重複執行也安全
  static Future<void> _createIndexes(Database db) async {
    // 列出未封存習慣並依排序取出
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_habits_archived_order
      ON habits (is_archived, sort_order)
    ''');
    // 依日期查詢全部習慣的紀錄(統計、小工具、跨習慣查詢)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_logs_date
      ON habit_logs (date_key)
    ''');
  }

  static Future<void> _ensureColumns(Database db) async {
    final habitCols = await db.rawQuery('PRAGMA table_info(habits)');
    bool hasHabit(String name) => habitCols.any((c) => c['name'] == name);

    if (!hasHabit('remind_time')) {
      await db.execute('ALTER TABLE habits ADD COLUMN remind_time TEXT');
    }
    if (!hasHabit('weekdays')) {
      await db.execute(
          'ALTER TABLE habits ADD COLUMN weekdays INTEGER NOT NULL DEFAULT 127');
    }
    // v5:每日目標次數。舊習慣預設 1,行為不變
    if (!hasHabit('daily_target')) {
      await db.execute(
          'ALTER TABLE habits ADD COLUMN daily_target INTEGER NOT NULL DEFAULT 1');
    }

    final logCols = await db.rawQuery('PRAGMA table_info(habit_logs)');
    bool hasLog(String name) => logCols.any((c) => c['name'] == name);

    // v5:當天完成次數。舊紀錄預設 1,搭配目標 1 仍算完成
    if (!hasLog('count')) {
      await db.execute(
          'ALTER TABLE habit_logs ADD COLUMN count INTEGER NOT NULL DEFAULT 1');
    }
  }
}