import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../buttons/app_button.dart';
import '../indicators/app_icon_badge.dart';

/// Shown when a list or chart has nothing yet: a soft tinted icon disc, a
/// short title, one line of help, and optionally one small action.
///
/// Place it inside an [AppCard] so empty sections keep the page's rhythm.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.color,
  });

  final IconData icon;
  final String? title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// Tint of the icon disc. Defaults to the brand colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconBadge(icon: icon, color: color ?? scheme.primary, size: 60, tinted: true),
          const SizedBox(height: AppSpacing.md),
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: actionLabel!,
              icon: actionIcon,
              onPressed: onAction,
              variant: AppButtonVariant.tonal,
              size: AppButtonSize.small,
              expanded: false,
            ),
          ],
        ],
      ),
    );
  }
}
