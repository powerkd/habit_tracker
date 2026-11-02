import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../features/habits/domain/habit.dart';

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
    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  /// 設定提醒時呼叫，會跳出系統授權視窗。回傳是否已授權。
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final a = await android?.requestNotificationsPermission();
    final i = await ios?.requestPermissions(
        alert: true, badge: true, sound: true);
    return (a ?? i ?? true);
  }

  /// 以目前的習慣清單重排所有提醒：先全部取消，再逐一排程。
  Future<void> syncAll(List<Habit> habits) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    for (final h in habits) {
      final t = h.remindTime;
      if (h.id == null || t == null) continue;
      await _schedule(h.id!, h.name, t);
    }
  }

  Future<void> _schedule(int id, String name, String hhmm) async {
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: id,
      title: '該打卡囉',
      body: name,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminder',
          '習慣提醒',
          channelDescription: '每日習慣打卡提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 每天重複
    );
  }
}
