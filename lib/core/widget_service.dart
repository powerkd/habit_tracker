import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetItem {
  final String name;
  final int count;
  final int target;
  const WidgetItem(this.name, this.count, this.target);
  bool get done => count >= target;
}

class WidgetService {
  WidgetService._();
  static final instance = WidgetService._();

  static const providerName = 'HabitWidgetProvider';
  static const qualifiedName = 'com.example.habit_tracker.HabitWidgetProvider';
  static const _maxRows = 4;

  Future<void> sync(List<WidgetItem> items, String dateKey,
      {required bool zh}) async {
    if (!Platform.isAndroid) return;
    try {
      final done = items.where((e) => e.done).length;
      await HomeWidget.saveWidgetData<String>('date', dateKey);
      await HomeWidget.saveWidgetData<int>('done', done);
      await HomeWidget.saveWidgetData<int>('total', items.length);
      await HomeWidget.saveWidgetData<String>('t_title', zh ? '今天' : 'Today');
      await HomeWidget.saveWidgetData<String>(
          't_empty', zh ? '今天沒有排程' : 'Nothing scheduled');
      await HomeWidget.saveWidgetData<String>(
          't_stale', zh ? '點開更新今日進度' : 'Open to refresh');

      final sorted = [...items]
        ..sort((a, b) => (a.done ? 1 : 0).compareTo(b.done ? 1 : 0));
      for (var i = 0; i < _maxRows; i++) {
        await HomeWidget.saveWidgetData<String>(
            'row$i', i < sorted.length ? _line(sorted[i]) : '');
      }
      final more = items.length - _maxRows;
      await HomeWidget.saveWidgetData<String>(
          'more', more > 0 ? (zh ? '還有 $more 項' : '$more more') : '');
      await HomeWidget.updateWidget(name: providerName);
    } catch (e) {
      debugPrint('更新小工具失敗：$e');
    }
  }

  String _line(WidgetItem e) {
    final p = e.target > 1 ? '  ${e.count}/${e.target}' : '';
    return '${e.done ? '✓' : '○'} ${e.name}$p';
  }
}
