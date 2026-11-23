import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Shows a small "Restoring…" style dialog that can't be dismissed while [task] runs, then closes it and returns
/// the task's result (or rethrows its error).
Future<T> runWithProgress<T>(BuildContext context, String message, Future<T> Function() task) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var open = true;
  showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  ).whenComplete(() => open = false);
  try {
    return await task();
  } finally {
    if (open) navigator.pop();
  }
}
