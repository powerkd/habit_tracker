import 'package:flutter/cupertino.dart';

/// iOS 風格的頁面轉場:左緣滑動返回 + 視差。
/// [fullscreen] 為 true 時,頁面從下方升起(適合「新增」表單)。
Route<T> appRoute<T>(Widget page, {bool fullscreen = false}) {
  return CupertinoPageRoute<T>(
    fullscreenDialog: fullscreen,
    builder: (_) => page,
  );
}
