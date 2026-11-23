import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../indicators/app_icon_badge.dart';
import '../lists/app_list_tile.dart';
import 'app_bottom_sheet.dart' show AppSheet;

/// One option in [showAppChoiceSheet].
class AppChoice<T> {
  const AppChoice({required this.value, required this.label, required this.icon, this.subtitle, this.color});

  final T value;
  final String label;
  final String? subtitle;
  final IconData icon;

  /// Tint of the icon badge; the theme's primary colour by default.
  final Color? color;
}

/// The app's one "pick from a list" popup: a bottom sheet with a title and a row per option (coloured icon, name,
/// detail), a tick on the current one. As tall as the options need, up to 80% of the screen; longer lists scroll.
/// Returns the picked value, or null when closed without picking.
Future<T?> showAppChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<AppChoice<T>> options,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * AppSheet.maxHeightFraction),
    isScrollControlled: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    for (final o in options)
                      AppListTile(
                        leading: AppIconBadge(
                          icon: o.icon,
                          color: o.color ?? scheme.primary,
                          size: AppSpacing.listIcon,
                        ),
                        title: o.label,
                        subtitle: o.subtitle,
                        titleStyle: o.value == selected
                            ? Theme.of(sheetContext).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
                            : null,
                        trailing: o.value == selected
                            ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                            : Icon(Icons.circle_outlined, color: scheme.outlineVariant),
                        onTap: () => Navigator.pop(sheetContext, o.value),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
