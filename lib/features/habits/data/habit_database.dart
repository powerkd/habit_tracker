import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HabitDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'habit_tracker.db');

    _db = await openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
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
            weekdays INTEGER NOT NULL DEFAULT 127
          )
        ''');
        await db.execute('''
          CREATE TABLE habit_logs (
            habit_id INTEGER NOT NULL,
            date_key TEXT NOT NULL,
            completed_at TEXT NOT NULL,
            PRIMARY KEY (habit_id, date_key),
            FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureColumns(db);
      },
      // 保險:即使版本號已是 4 但欄位缺失,也會在開啟時補上
      onOpen: (db) async {
        await _ensureColumns(db);
      },
    );
    return _db!;
  }

  static Future<void> _ensureColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(habits)');
    bool has(String name) => columns.any((c) => c['name'] == name);

    if (!has('remind_time')) {
      await db.execute('ALTER TABLE habits ADD COLUMN remind_time TEXT');
    }
    if (!has('weekdays')) {
      await db.execute(
          'ALTER TABLE habits ADD COLUMN weekdays INTEGER NOT NULL DEFAULT 127');
    }
  }
}