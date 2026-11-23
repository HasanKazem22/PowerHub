import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gloss.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

enum AppButtonVariant {
  /// Glossy brand green, white text. The main action of a page or sheet.
  primary,

  /// Soft green tint. Secondary action.
  tonal,

  /// White with an outline.
  outline,

  /// Text only, red. Destructive secondary actions ("Remove account").
  danger,
}

enum AppButtonSize {
  /// Inline actions: empty states, banners, cards.
  small(AppSpacing.buttonSmall, 13, 16, AppSpacing.lg),

  /// Default for every form, sheet and page action.
  medium(AppSpacing.buttonMedium, 14, 18, AppSpacing.xl),

  /// Rare hero actions.
  large(AppSpacing.buttonLarge, 15, 20, AppSpacing.xxl);

  const AppButtonSize(this.height, this.fontSize, this.iconSize, this.padding);
  final double height;
  final double fontSize;
  final double iconSize;
  final double padding;
}

/// The app's one button, so every button has the same shape, height and type
/// on every screen. Full width by default; set [expanded] false to size it to
/// its label.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (variant == AppButtonVariant.primary) {
      return _GlossyButton(label: label, icon: icon, onPressed: onPressed, expanded: expanded, size: size);
    }

    final scheme = Theme.of(context).colorScheme;
    final minSize = Size(expanded ? double.infinity : 0, size.height);
    final textStyle = TextStyle(fontFamily: appFontFamily, fontSize: size.fontSize, fontWeight: FontWeight.w600);
    final padding = EdgeInsets.symmetric(horizontal: size.padding);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));

    final style = switch (variant) {
      AppButtonVariant.tonal => FilledButton.styleFrom(
        minimumSize: minSize,
        padding: padding,
        textStyle: textStyle,
        shape: shape,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 0,
      ),
      AppButtonVariant.outline => OutlinedButton.styleFrom(
        minimumSize: minSize,
        padding: padding,
        textStyle: textStyle,
        shape: shape,
      ),
      _ => TextButton.styleFrom(
        minimumSize: minSize,
        padding: padding,
        textStyle: textStyle,
        shape: shape,
        foregroundColor: AppColors.error,
      ),
    };

    final child = _Label(label: label, icon: icon, iconSize: size.iconSize);
    return switch (variant) {
      AppButtonVariant.tonal => FilledButton(onPressed: onPressed, style: style, child: child),
      AppButtonVariant.outline => OutlinedButton(onPressed: onPressed, style: style, child: child),
      _ => TextButton(onPressed: onPressed, style: style, child: child),
    };
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, required this.icon, required this.iconSize, this.color, this.style});
  final String label;
  final IconData? icon;
  final double iconSize;
  final Color? color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: iconSize, color: color), const SizedBox(width: AppSpacing.sm)],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
      ],
    );
  }
}

/// Primary button: glossy brand-green gradient with a soft green glow.
class _GlossyButton extends StatelessWidget {
  const _GlossyButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.expanded,
    required this.size,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.md);
    final fg = enabled ? AppColors.onBrand : scheme.outline;
    return Semantics(
      button: true,
      enabled: enabled,
      child: SizedBox(
        width: expanded ? double.infinity : null,
        height: size.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: enabled ? AppGloss.brandButton : null,
            color: enabled ? null : scheme.surfaceContainerHigh,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.24),
                      blurRadius: 12,
                      spreadRadius: -4,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Stack(
                children: [
                  if (enabled)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(decoration: BoxDecoration(gradient: AppGloss.sheen(strength: 0.16))),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.padding),
                    child: Center(
                      widthFactor: expanded ? null : 1,
                      child: _Label(
                        label: label,
                        icon: icon,
                        iconSize: size.iconSize,
                        color: fg,
                        style: TextStyle(
                          fontFamily: appFontFamily,
                          fontSize: size.fontSize,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
