import 'package:flutter/cupertino.dart';

import 'haptics.dart';

/// iOS 風格確認對話框。回傳 true 代表按下確認。
Future<bool> showIosConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final r = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          isDestructiveAction: destructive,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r == true;
}

/// iOS 風格單按鈕提示框
Future<void> showIosAlert(
  BuildContext context, {
  required String title,
  required String message,
  required String okLabel,
}) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(okLabel),
        ),
      ],
    ),
  );
}

/// iOS 風格底部選單(Action Sheet)。取消時回傳 null。
Future<T?> showIosPicker<T>(
  BuildContext context, {
  required String title,
  required Map<T, String> options,
  required T value,
  required String cancelLabel,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(title),
      actions: [
        for (final e in options.entries)
          CupertinoActionSheetAction(
            isDefaultAction: e.key == value,
            onPressed: () {
              Haptics.selection();
              Navigator.pop(ctx, e.key);
            },
            child: Text(e.value),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(cancelLabel),
      ),
    ),
  );
}
