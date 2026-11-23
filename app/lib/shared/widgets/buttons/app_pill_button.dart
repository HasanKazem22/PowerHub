import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gloss.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';

enum AppPillVariant {
  /// Gold pill with dark text: the action on a green gradient card.
  gold,

  /// White pill with a faint outline and shadow: "See more" / "Show less".
  light,
}

/// Small rounded pill button.
class AppPillButton extends StatelessWidget {
  const AppPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leadingIcon,
    this.variant = AppPillVariant.gold,
  });

  final String label;
  final VoidCallback? onPressed;

  /// After the label (e.g. an arrow or chevron).
  final IconData? icon;

  /// Before the label.
  final IconData? leadingIcon;
  final AppPillVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      AppPillVariant.gold => (AppColors.gold, AppColors.onGold, BorderSide.none),
      AppPillVariant.light => (
        context.palette.card,
        scheme.primary,
        BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
    };
    final disabled = onPressed == null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: variant == AppPillVariant.light && !context.isDark ? AppShadows.pill : null,
      ),
      child: Material(
        color: disabled
            ? Colors.white.withValues(alpha: 0.16)
            : (variant == AppPillVariant.gold ? Colors.transparent : bg),
        shape: StadiumBorder(side: side),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(gradient: variant == AppPillVariant.gold && !disabled ? AppGloss.goldButton : null),
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.fromLTRB(leadingIcon == null ? 16 : 12, 9, icon == null ? 16 : 12, 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 16, color: disabled ? Colors.white70 : fg),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: disabled ? Colors.white70 : fg,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(icon, size: 18, color: disabled ? Colors.white70 : fg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
