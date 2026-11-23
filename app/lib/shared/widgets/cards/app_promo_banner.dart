import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'app_gradient_card.dart';

/// Campaign-style banner: an icon "illustration" in a white disc, a small
/// badge, a bold title and a line of detail, with a gold "Details" pill, and an
/// optional × in the corner ([onClose]).
class AppPromoBanner extends StatelessWidget {
  const AppPromoBanner({
    super.key,
    required this.icon,
    required this.badge,
    required this.title,
    required this.detail,
    this.actionLabel = 'Open',
    this.colors = AppGradientCard.brandGradient,
    this.onTap,
    this.onClose,
    this.closeTooltip = 'Close',
  });

  final IconData icon;
  final String badge;
  final String title;
  final String detail;
  final String actionLabel;
  final List<Color> colors;
  final VoidCallback? onTap;

  /// Shows an × in the top corner that calls this.
  final VoidCallback? onClose;
  final String closeTooltip;

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      colors: colors,
      radius: AppRadius.lg,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.25,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, 14, onClose == null ? AppSpacing.lg : 36, 30),
              child: Row(
                children: [
                  _Illustration(icon: icon, color: colors.first),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, height: 1.3, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (onClose != null)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  tooltip: closeTooltip,
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),
            Positioned(
              right: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.onGold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.95),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, size: 28, color: color),
          ),
        ],
      ),
    );
  }
}
