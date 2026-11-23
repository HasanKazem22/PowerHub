import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Shared bottom sheet rules.
abstract final class AppSheet {
  /// The tallest a sheet gets, as a share of the screen height.
  static const maxHeightFraction = 0.8;
}

/// Opens a bottom sheet with the app's standard layout: drag handle, title,
/// optional subtitle, scrollable content, and room for the keyboard.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // Above the bottom navigation, not inside the current tab.
    useRootNavigator: true,
    // Never taller than 80% of the screen: the app stays visible behind it; longer content scrolls.
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * AppSheet.maxHeightFraction),
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: Theme.of(sheetContext).textTheme.bodySmall),
              ],
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}
