import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../habits/data/habit_database.dart';

class BackupService {
  static const _format = 'habit_tracker_backup';
  static const _version = 1;

  static final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _timeRe = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// 匯出成 JSON 檔(放在暫存資料夾,交給分享選單)
  Future<File> export() async {
    final db = await HabitDatabase.instance;
    final habits = await db.query('habits', orderBy: 'sort_order ASC, id ASC');
    final logs =
        await db.query('habit_logs', orderBy: 'habit_id ASC, date_key ASC');

    final payload = {
      'format': _format,
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': habits,
      'logs': logs,
    };

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/habit_tracker_backup_$stamp.json');
    return file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  /// 還原備份:會「取代」目前所有資料。回傳匯入的筆數。
  Future<({int habits, int logs})> importJson(String text) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw const FormatException('檔案不是有效的 JSON');
    }
    if (decoded is! Map || decoded['format'] != _format) {
      throw const FormatException('不是 Habit Tracker 的備份檔');
    }
    final v = decoded['version'];
    if (v is! int || v > _version) {
      throw const FormatException('備份檔版本較新,請先更新 app');
    }
    final rawHabits = decoded['habits'];
    final rawLogs = decoded['logs'];
    if (rawHabits is! List || rawLogs is! List) {
      throw const FormatException('備份檔內容不完整');
    }

    // 先全部驗證、清理,通過才寫入資料庫
    final habits = <Map<String, Object?>>[];
    final ids = <int>{};
    for (var i = 0; i < rawHabits.length; i++) {
      final h = _cleanHabit(rawHabits[i], i);
      if (!ids.add(h['id'] as int)) {
        throw FormatException('習慣 id 重複:${h['id']}');
      }
      habits.add(h);
    }
    final logs = <Map<String, Object?>>[];
    final seen = <String>{};
    for (var i = 0; i < rawLogs.length; i++) {
      final l = _cleanLog(rawLogs[i], i, ids);
      if (seen.add('${l['habit_id']}|${l['date_key']}')) logs.add(l);
    }

    final db = await HabitDatabase.instance;
    await db.transaction((txn) async {
      await txn.delete('habit_logs');
      await txn.delete('habits');
      final batch = txn.batch();
      for (final h in habits) {
        batch.insert('habits', h);
      }
      for (final l in logs) {
        batch.insert('habit_logs', l);
      }
      await batch.commit(noResult: true);
    });

    return (habits: habits.length, logs: logs.length);
  }

  Map<String, Object?> _cleanHabit(Object? raw, int i) {
    String err(String f) => '第 ${i + 1} 筆習慣的「$f」格式錯誤';
    if (raw is! Map) throw FormatException(err('資料'));

    final id = raw['id'];
    final name = raw['name'];
    final iconKey = raw['icon_key'];
    final color = raw['color_value'];
    final start = raw['start_date'];
    if (id is! int) throw FormatException(err('id'));
    if (name is! String || name.trim().isEmpty) {
      throw FormatException(err('name'));
    }
    if (iconKey is! String) throw FormatException(err('icon_key'));
    if (color is! int) throw FormatException(err('color_value'));
    if (start is! String || !_dateRe.hasMatch(start)) {
      throw FormatException(err('start_date'));
    }

    final desc = raw['description'];
    final remind = raw['remind_time'];
    final created = raw['created_at'];
    final archived = raw['is_archived'];
    final order = raw['sort_order'];
    final wd = raw['weekdays'];
    final weekdays = (wd is int && wd >= 1 && wd <= 127) ? wd : 127;

    return {
      'id': id,
      'name': name,
      'description': desc is String ? desc : null,
      'icon_key': iconKey,
      'color_value': color,
      'start_date': start,
      'weekdays': weekdays,
      'created_at':
          created is String ? created : DateTime.now().toUtc().toIso8601String(),
      'is_archived': archived == 1 ? 1 : 0,
      'sort_order': order is int ? order : 0,
      'remind_time':
          (remind is String && _timeRe.hasMatch(remind)) ? remind : null,
    };
  }

  Map<String, Object?> _cleanLog(Object? raw, int i, Set<int> habitIds) {
    String err(String f) => '第 ${i + 1} 筆打卡紀錄的「$f」格式錯誤';
    if (raw is! Map) throw FormatException(err('資料'));

    final hid = raw['habit_id'];
    final key = raw['date_key'];
    if (hid is! int || !habitIds.contains(hid)) {
      throw FormatException(err('habit_id'));
    }
    if (key is! String || !_dateRe.hasMatch(key)) {
      throw FormatException(err('date_key'));
    }
    final at = raw['completed_at'];
    return {
      'habit_id': hid,
      'date_key': key,
      'completed_at':
          at is String ? at : DateTime.now().toUtc().toIso8601String(),
    };
  }
}
