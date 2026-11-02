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
        'remind_time': habit.remindTime, // 新增;null 代表清除提醒
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
      await txn.delete('habit_logs',
          where: 'habit_id = ?', whereArgs: [id]);
      await txn.delete('habits', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<Set<String>> getCompletedKeys(int habitId) async {
    final db = await HabitDatabase.instance;
    final rows = await db.query('habit_logs',
        columns: ['date_key'],
        where: 'habit_id = ?',
        whereArgs: [habitId]);
    return rows.map((r) => r['date_key'] as String).toSet();
  }

  Future<void> complete(int habitId, String dateKey) async {
    final db = await HabitDatabase.instance;
    await db.insert(
      'habit_logs',
      {
        'habit_id': habitId,
        'date_key': dateKey,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> uncomplete(int habitId, String dateKey) async {
    final db = await HabitDatabase.instance;
    await db.delete('habit_logs',
        where: 'habit_id = ? AND date_key = ?',
        whereArgs: [habitId, dateKey]);
  }
}
