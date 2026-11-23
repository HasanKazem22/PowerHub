import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gloss.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/indicators/app_icon_badge.dart';

/// A small icon floating around the main one.
class OnboardingSatellite {
  const OnboardingSatellite(this.icon, this.color, this.alignment);
  final IconData icon;
  final Color color;

  /// Position inside the illustration's square (-1..1 on each axis).
  final Alignment alignment;
}

/// Slide artwork built from the app's own pieces: a soft green halo, a glossy
/// white disc holding the main icon on the brand gradient, and a few icon
/// discs floating around it, so the slides look like the app itself.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.icon, required this.satellites, required this.size});

  final IconData icon;
  final List<OnboardingSatellite> satellites;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final disc = size * 0.56;
    final core = size * 0.34;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.primarySoft, AppColors.primarySoft.withValues(alpha: 0)],
                stops: const [0.45, 1],
              ),
            ),
          ),
          // Thin orbit ring.
          Container(
            width: size * 0.84,
            height: size * 0.84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.12), width: 1.2),
            ),
          ),
          // Glossy white disc.
          Container(
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.card, palette.cardSheenEnd],
              ),
              border: Border.all(color: palette.cardEdge),
              boxShadow: AppShadows.card(palette.cardShadow),
            ),
            alignment: Alignment.center,
            // Main icon on the brand gradient.
            child: Container(
              width: core,
              height: core,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGloss.brandButton,
                boxShadow: AppShadows.hero(AppColors.brand),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGloss.sheen(strength: 0.22)),
                child: Icon(icon, color: AppColors.onBrand, size: core * 0.46),
              ),
            ),
          ),
          for (final s in satellites)
            Align(
              alignment: s.alignment,
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: AppShadows.card(palette.cardShadow)),
                child: AppIconBadge(icon: s.icon, color: s.color, size: size * 0.19),
              ),
            ),
          // Gold sparkle, the logo's second colour.
          Align(
            alignment: const Alignment(0.42, -0.62),
            child: Container(
              width: size * 0.035,
              height: size * 0.035,
              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
            ),
          ),
          Align(
            alignment: const Alignment(-0.5, 0.58),
            child: Container(
              width: size * 0.025,
              height: size * 0.025,
              decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.7), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
