import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../indicators/app_icon_badge.dart';
import '../lists/app_list_tile.dart';
import 'app_bottom_sheet.dart' show AppSheet;

/// One option in [showAppActionSheet].
class AppSheetAction {
  const AppSheetAction({required this.icon, required this.label, required this.onTap, this.subtitle, this.color});

  final IconData icon;
  final String label;
  final String? subtitle;

  /// Tint of the icon badge. Defaults to the theme's primary colour.
  final Color? color;

  /// Runs after the sheet has closed.
  final VoidCallback onTap;
}

/// Bottom sheet with a list of options (e.g. the "+" menu, item actions). As tall as its options need, up to 80% of
/// the screen; beyond that the options scroll under a fixed title.
Future<void> showAppActionSheet(BuildContext context, {String? title, required List<AppSheetAction> actions}) {
  return showModalBottomSheet<void>(
    context: context,
    // Above the bottom navigation, not inside the current tab.
    useRootNavigator: true,
    // Never taller than 80% of the screen: the app stays visible behind it; longer content scrolls.
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * AppSheet.maxHeightFraction),
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.sm),
              child: Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final a in actions)
                    AppListTile(
                      leading: AppIconBadge(
                        icon: a.icon,
                        color: a.color ?? Theme.of(sheetContext).colorScheme.primary,
                        size: AppSpacing.listIcon,
                      ),
                      title: a.label,
                      subtitle: a.subtitle,
                      trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(sheetContext).colorScheme.outline),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        a.onTap();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
