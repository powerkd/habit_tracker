import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/habits/data/habit_database.dart';
import 'package:habit_tracker/features/habits/data/habit_repository.dart';
import 'package:habit_tracker/features/habits/domain/habit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late HabitRepository repo;
  late Directory tempDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('habit_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    repo = HabitRepository();
    final db = await HabitDatabase.instance;
    await db.delete('habit_logs');
    await db.delete('habits');
  });

  tearDownAll(() async {
    final db = await HabitDatabase.instance;
    await db.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<int> addSample([String name = '閱讀']) =>
      repo.addHabit(Habit(name: name, startDate: '2026-11-01'));

  test('新增後可從進行中清單讀到', () async {
    await addSample();
    final list = await repo.getActiveHabits();
    expect(list.length, 1);
    expect(list.first.name, '閱讀');
  });

  test('封存後從進行中消失,出現在已封存;還原後回來', () async {
    final id = await addSample();

    await repo.archiveHabit(id);
    expect(await repo.getActiveHabits(), isEmpty);
    expect((await repo.getArchivedHabits()).length, 1);

    await repo.unarchiveHabit(id);
    expect((await repo.getActiveHabits()).length, 1);
    expect(await repo.getArchivedHabits(), isEmpty);
  });

  test('同一天重複完成只會有一筆', () async {
    final id = await addSample();
    await repo.complete(id, '2026-11-02');
    await repo.complete(id, '2026-11-02');
    expect(await repo.getCompletedKeys(id), {'2026-11-02'});
  });
  

  test('取消完成會移除該日紀錄', () async {
    final id = await addSample();
    await repo.complete(id, '2026-11-01');
    await repo.complete(id, '2026-11-02');
    await repo.uncomplete(id, '2026-11-02');
    expect(await repo.getCompletedKeys(id), {'2026-11-01'});
  });

  test('編輯習慣不影響歷史打卡', () async {
    final id = await addSample();
    await repo.complete(id, '2026-11-02');

    final old = (await repo.getHabit(id))!;
    await repo.updateHabit(old.copyWith(name: '閱讀 30 分鐘'));

    final updated = (await repo.getHabit(id))!;
    expect(updated.name, '閱讀 30 分鐘');
    expect(await repo.getCompletedKeys(id), {'2026-11-02'});
  });

  test('永久刪除會同時清除打卡紀錄', () async {
    final id = await addSample();
    await repo.complete(id, '2026-11-02');

    await repo.deleteHabit(id);

    expect(await repo.getHabit(id), isNull);
    expect(await repo.getCompletedKeys(id), isEmpty);
  });

  test('不同習慣的紀錄互不干擾', () async {
    final a = await addSample('A');
    final b = await addSample('B');
    await repo.complete(a, '2026-11-02');
    expect(await repo.getCompletedKeys(b), isEmpty);
  });
}
