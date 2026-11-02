import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app/app.dart';
import 'core/notification_service.dart'; // 新增

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 桌面平台需要初始化 FFI
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initializeDateFormatting('zh_TW');

  // 新增：通知初始化。失敗不應讓 app 打不開
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('通知初始化失敗：$e');
  }

  runApp(const ProviderScope(child: HabitApp()));
}
