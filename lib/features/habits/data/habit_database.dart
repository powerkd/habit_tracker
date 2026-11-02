import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HabitDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'habit_tracker.db');

    _db = await openDatabase(
      path,
      version: 3,
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
            remind_time TEXT
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
        // 從 1 升級：兩個欄位都沒有
        if (oldVersion < 2) {
          final columns = await db.rawQuery("PRAGMA table_info(habits)");
          final hasremindTime = columns.any((c) => c['name'] == 'remind_time');
          if (!hasremindTime) {
            await db.execute('ALTER TABLE habits ADD COLUMN remind_time TEXT');
          }
        }
      },
    );
    return _db!;
  }
}
