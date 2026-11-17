import 'dart:async';

import 'package:flutter/widgets.dart';

/// 偵測「日期已變更」並通知外部刷新。
/// - App 在前景時：以計時器等到下一個午夜觸發。
/// - App 從背景回來時：立即比對日期。
class DayChangeWatcher extends StatefulWidget {
  const DayChangeWatcher({
    super.key,
    required this.onDayChanged,
    required this.child,
  });

  final VoidCallback onDayChanged;
  final Widget child;

  @override
  State<DayChangeWatcher> createState() => _DayChangeWatcherState();
}

class _DayChangeWatcherState extends State<DayChangeWatcher>
    with WidgetsBindingObserver {
  late DateTime _lastDay;
  Timer? _timer;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _lastDay = _today();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    // 多加 1 秒，避免剛好落在邊界前
    final wait = nextMidnight.difference(now) + const Duration(seconds: 1);
    _timer = Timer(wait, _check);
  }

  void _check() {
    final today = _today();
    if (today != _lastDay) {
      _lastDay = today;
      widget.onDayChanged();
    }
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}