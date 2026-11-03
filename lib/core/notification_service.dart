import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../features/habits/domain/habit.dart';
import '../features/habits/presentation/habit_detail_page.dart';
import 'app_navigator.dart';
import '../features/habits/domain/weekday_utils.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // 取不到時區時退回台北時間，避免整個初始化失敗
      debugPrint('取得時區失敗，改用 Asia/Taipei：$e');
      tz.setLocalLocation(tz.getLocation('Asia/Taipei'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _openHabit(response.payload);
      },
    );
    _ready = true;

    // app 被完全關閉時，點通知啟動的情況
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch!.notificationResponse?.payload;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openHabit(payload));
    }
  }

  /// 點通知後開啟對應習慣的詳情頁
  void _openHabit(String? payload) {
    final id = int.tryParse(payload ?? '');
    if (id == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => HabitDetailPage(habitId: id),
      ),
    );
  }

  /// 設定提醒時呼叫，會跳出系統授權視窗。回傳是否已授權。
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final a = await android?.requestNotificationsPermission();
    final i =
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return (a ?? i ?? true);
  }

  /// 以目前的習慣清單重排所有提醒：先全部取消，再逐一排程。
  Future<void> syncAll(List<Habit> habits) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    for (final h in habits) {
      final t = h.remindTime;
      if (h.id == null || t == null) continue;
      await _schedule(h.id!, h.name, t, h.weekdays);
    }
  }

   Future<void> _schedule(
      int habitId, String name, String hhmm, int weekdays) async {
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
  
    if (weekdays == allWeekdays) {
      await _scheduleOne(
        notifId: habitId * 10,
        habitId: habitId,
        name: name,
        when: _nextOccurrence(hour, minute, null),
        repeat: DateTimeComponents.time,
      );
      return;
    }
  
    for (var wd = 1; wd <= 7; wd++) {
      if (!weekdayRuns(weekdays, wd)) continue;
      await _scheduleOne(
        notifId: habitId * 10 + wd,
        habitId: habitId,
        name: name,
        when: _nextOccurrence(hour, minute, wd),
        repeat: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }
  
  /// 下一次觸發時間。weekday 為 null 代表任何一天
  tz.TZDateTime _nextOccurrence(int hour, int minute, int? weekday) {
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (when.isBefore(now) ||
        (weekday != null && when.weekday != weekday)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }
  
  Future<void> _scheduleOne({
    required int notifId,
    required int habitId,
    required String name,
    required tz.TZDateTime when,
    required DateTimeComponents repeat,
  }) async {
    await _plugin.zonedSchedule(
      id: notifId,
      title: '該打卡囉',
      body: name,
      payload: habitId.toString(),
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminder',
          '習慣提醒',
          channelDescription: '習慣打卡提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: repeat,
    );
  }
}
