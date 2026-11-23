import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gloss.dart';
import '../../../core/theme/app_spacing.dart';

/// Glossy brand-gradient surface: a sheen across the top, soft light in the
/// top-right corner, faint angled light streaks, and a coloured glow
/// underneath. Base of hero cards, the balance card and promo banners.
class AppGradientCard extends StatelessWidget {
  const AppGradientCard({
    super.key,
    required this.child,
    this.colors = brandGradient,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.xl,
    this.onTap,
  });

  /// Deep green → signature green → lighter green.
  static const brandGradient = [AppColors.primaryDark, AppColors.primary, AppColors.brand];

  /// Deep amber → gold, for gold-themed promos.
  static const goldGradient = [AppColors.goldDeep, AppColors.goldMid, AppColors.gold];

  final Widget child;
  final List<Color> colors;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: AppShadows.hero(colors[colors.length ~/ 2])),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  // Gloss: light across the top half.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(decoration: BoxDecoration(gradient: AppGloss.sheen(strength: 0.14))),
                    ),
                  ),
                  // Angled light streaks, the way printed campaign art is lit.
                  Positioned(
                    left: -40,
                    top: -80,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Container(width: 60, height: 360, color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 60,
                    top: -80,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Container(width: 20, height: 360, color: Colors.white.withValues(alpha: 0.04)),
                      ),
                    ),
                  ),
                  // Soft light from the top-right corner.
                  Positioned(
                    right: -40,
                    top: -60,
                    child: IgnorePointer(
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(padding: padding, child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
