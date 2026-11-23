import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';

enum AppBannerType { info, warning, error, success }

/// A short status message or tip: a soft tinted panel with the icon on a
/// slightly deeper tint. Informs without alarming.
class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.message,
    this.type = AppBannerType.info,
    this.icon,
    this.onTap,
    this.onDismiss,
  });

  final String message;
  final AppBannerType type;

  /// Defaults to an icon matching [type].
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, IconData defaultIcon) = switch (type) {
      AppBannerType.info => (AppColors.infoContainer, AppColors.infoText, Icons.info_outline_rounded),
      AppBannerType.warning => (AppColors.warningContainer, AppColors.warningText, Icons.schedule_rounded),
      AppBannerType.error => (AppColors.errorContainer, AppColors.error, Icons.error_outline_rounded),
      AppBannerType.success => (AppColors.successContainer, AppColors.successText, Icons.check_circle_outline_rounded),
    };
    // In dark mode, keep the hue but on a dark translucent panel.
    final bg = context.isDark ? foreground.withValues(alpha: 0.18) : background;
    final fg = context.isDark ? Color.lerp(foreground, Colors.white, 0.55)! : foreground;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, 14, AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: fg.withValues(alpha: 0.10), shape: BoxShape.circle),
                child: Icon(icon ?? defaultIcon, color: fg, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: AppSpacing.sm),
                InkResponse(
                  onTap: onDismiss,
                  radius: 18,
                  child: Icon(Icons.close_rounded, color: fg, size: 18),
                ),
              ] else if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.chevron_right_rounded, color: fg, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
