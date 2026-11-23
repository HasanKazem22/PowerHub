import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';

/// Glossy white card: white at the top easing to a warm off-white, a hairline
/// light edge, and a very soft lifted shadow. The base of every grouped block.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.radius = AppRadius.lg,
    this.onTap,
  });

  final Widget child;

  /// Use [EdgeInsets.zero] for cards that hold list rows.
  final EdgeInsetsGeometry padding;

  /// A flat colour instead of the glossy gradient.
  final Color? color;

  /// [AppRadius.lg] for cards, [AppRadius.panel] for large panels.
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: color,
        gradient: color == null
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.card, palette.cardSheenEnd],
              )
            : null,
        border: Border.all(color: palette.cardEdge, width: 0.8),
        boxShadow: AppShadows.card(palette.cardShadow),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}
