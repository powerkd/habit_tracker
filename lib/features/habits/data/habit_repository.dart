import 'package:sqflite/sqflite.dart';
import '../domain/habit.dart';
import 'habit_database.dart';

/// 刪除前的快照,供「復原」使用
class DeletedHabitSnapshot {
  final Map<String, Object?> habit;
  final List<Map<String, Object?>> logs;
  const DeletedHabitSnapshot(this.habit, this.logs);
}

class HabitRepository {
  /// 刪除習慣與打卡紀錄,並回傳快照供復原
  Future<DeletedHabitSnapshot?> deleteHabitWithSnapshot(int id) async {
    final db = await HabitDatabase.instance;
    final rows =
        await db.query('habits', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final logs =
        await db.query('habit_logs', where: 'habit_id = ?', whereArgs: [id]);

    await db.transaction((txn) async {
      await txn.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
      await txn.delete('habits', where: 'id = ?', whereArgs: [id]);
    });

    return DeletedHabitSnapshot(
      Map<String, Object?>.of(rows.first),
      logs.map((e) => Map<String, Object?>.of(e)).toList(),
    );
  }

  /// 用快照還原(保留原本的 id,提醒的通知 id 也會一致)
  Future<void> restoreSnapshot(DeletedHabitSnapshot s) async {
    final db = await HabitDatabase.instance;
    await db.transaction((txn) async {
      await txn.insert('habits', s.habit,
          conflictAlgorithm: ConflictAlgorithm.replace);
      final batch = txn.batch();
      for (final row in s.logs) {
        batch.insert('habit_logs', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Habit>> getActiveHabits() async {
    final db = await HabitDatabase.instance;
    final rows = await db.query(
      'habits',
      where: 'is_archived = 0',
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(Habit.fromMap).toList();
  }

  Future<Habit?> getHabit(int id) async {
    final db = await HabitDatabase.instance;
    final rows = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Habit.fromMap(rows.first);
  }

  Future<int> addHabit(Habit habit) async {
    final db = await HabitDatabase.instance;
    // 新習慣排在最後
    final r = await db.rawQuery(
        'SELECT COALESCE(MAX(sort_order), -1) + 1 AS n FROM habits');
    final next = (r.first['n'] as int?) ?? 0;

    final map = habit.toMap()
      ..remove('id')
      ..['sort_order'] = next
      ..['created_at'] = DateTime.now().toUtc().toIso8601String();
    return db.insert('habits', map);
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await HabitDatabase.instance;
    await db.update(
      'habits',
      {
        'name': habit.name,
        'description': habit.description,
        'icon_key': habit.iconKey,
        'color_value': habit.colorValue,
        'remind_time': habit.remindTime, // null 代表清除提醒
        'weekdays': habit.weekdays,
        'daily_target': habit.dailyTarget,
      },
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// 儲存拖曳後的順序
  Future<void> updateOrder(List<int> orderedIds) async {
    final db = await HabitDatabase.instance;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 0; i < orderedIds.length; i++) {
        batch.update('habits', {'sort_order': i},
            where: 'id = ?', whereArgs: [orderedIds[i]]);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> archiveHabit(int id) async {
    final db = await HabitDatabase.instance;
    await db.update('habits', {'is_archived': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Habit>> getArchivedHabits() async {
    final db = await HabitDatabase.instance;
    final rows = await db.query(
      'habits',
      where: 'is_archived = 1',
      orderBy: 'id DESC',
    );
    return rows.map(Habit.fromMap).toList();
  }

  Future<void> unarchiveHabit(int id) async {
    final db = await HabitDatabase.instance;
    await db.update('habits', {'is_archived': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  /// 永久刪除習慣與其所有打卡紀錄
  Future<void> deleteHabit(int id) async {
    final db = await HabitDatabase.instance;
    await db.transaction((txn) async {
      await txn.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
      await txn.delete('habits', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// 達標的日期(次數 >= 每日目標)。連續天數只用這個計算。
  Future<Set<String>> getCompletedKeys(int habitId) async {
    final db = await HabitDatabase.instance;
    final rows = await db.rawQuery('''
      SELECT l.date_key FROM habit_logs l
      JOIN habits h ON h.id = l.habit_id
      WHERE l.habit_id = ? AND l.count >= h.daily_target
    ''', [habitId]);
    return rows.map((r) => r['date_key'] as String).toSet();
  }

  /// 每個有紀錄的日期的次數(含未達標),供今日頁與日曆顯示進度
  Future<Map<String, int>> getLogCounts(int habitId) async {
    final db = await HabitDatabase.instance;
    final rows = await db.query(
      'habit_logs',
      columns: ['date_key', 'count'],
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
    return {
      for (final r in rows) r['date_key'] as String: (r['count'] as int?) ?? 1,
    };
  }

  /// 次數 +1,達標後不再增加。回傳增加後的次數。
  Future<int> increment(int habitId, String dateKey) async {
    final db = await HabitDatabase.instance;
    return db.transaction((txn) async {
      final h = await txn.query('habits',
          columns: ['daily_target'],
          where: 'id = ?',
          whereArgs: [habitId],
          limit: 1);
      if (h.isEmpty) return 0;
      final target = (h.first['daily_target'] as int?) ?? 1;

      final rows = await txn.query('habit_logs',
          columns: ['count'],
          where: 'habit_id = ? AND date_key = ?',
          whereArgs: [habitId, dateKey],
          limit: 1);
      final current = rows.isEmpty ? 0 : ((rows.first['count'] as int?) ?? 1);
      if (current >= target) return current;

      if (rows.isEmpty) {
        await txn.insert('habit_logs', {
          'habit_id': habitId,
          'date_key': dateKey,
          'count': 1,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        await txn.update('habit_logs', {'count': current + 1},
            where: 'habit_id = ? AND date_key = ?',
            whereArgs: [habitId, dateKey]);
      }
      return current + 1;
    });
  }

  /// 次數 -1,降到 0 就刪除該筆紀錄。回傳減少後的次數。
  Future<int> decrement(int habitId, String dateKey) async {
    final db = await HabitDatabase.instance;
    return db.transaction((txn) async {
      final rows = await txn.query('habit_logs',
          columns: ['count'],
          where: 'habit_id = ? AND date_key = ?',
          whereArgs: [habitId, dateKey],
          limit: 1);
      if (rows.isEmpty) return 0;
      final current = (rows.first['count'] as int?) ?? 1;
      if (current <= 1) {
        await txn.delete('habit_logs',
            where: 'habit_id = ? AND date_key = ?',
            whereArgs: [habitId, dateKey]);
        return 0;
      }
      await txn.update('habit_logs', {'count': current - 1},
          where: 'habit_id = ? AND date_key = ?',
          whereArgs: [habitId, dateKey]);
      return current - 1;
    });
  }

  /// 直接標記為達標(補打卡用),次數設為目前的每日目標
  Future<void> complete(int habitId, String dateKey) async {
    final db = await HabitDatabase.instance;
    await db.transaction((txn) async {
      final h = await txn.query('habits',
          columns: ['daily_target'],
          where: 'id = ?',
          whereArgs: [habitId],
          limit: 1);
      if (h.isEmpty) return;
      final target = (h.first['daily_target'] as int?) ?? 1;

      await txn.insert(
        'habit_logs',
        {
          'habit_id': habitId,
          'date_key': dateKey,
          'count': target,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await txn.update(
        'habit_logs',
        {'count': target},
        where: 'habit_id = ? AND date_key = ? AND count < ?',
        whereArgs: [habitId, dateKey, target],
      );
    });
  }

  /// 清除該日全部次數
  Future<void> uncomplete(int habitId, String dateKey) async {
    final db = await HabitDatabase.instance;
    await db.delete('habit_logs',
        where: 'habit_id = ? AND date_key = ?',
        whereArgs: [habitId, dateKey]);
  }
}
