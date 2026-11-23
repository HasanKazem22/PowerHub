import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// The Bear Tech company logo (the same file as the other Bear Tech apps:
/// black "Bear Tech" lettering with the bear's head).
///
/// The lettering is black, so on dark backgrounds set [onDark] to place it
/// on a small white card.
class BearTechLogo extends StatelessWidget {
  const BearTechLogo({super.key, this.height = 32, this.onDark = false});

  static const asset = 'assets/images/bear_tech_logo.png';

  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: AppConstants.company,
      // Never show Flutter's red error box for a logo: fall back to the name.
      errorBuilder: (context, _, _) => SizedBox(
        height: height,
        child: Center(
          child: Text(
            AppConstants.company,
            style: TextStyle(
              fontSize: height * 0.42,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
    if (!onDark) return image;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: height * 0.35, vertical: height * 0.18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: image,
    );
  }
}

/// "from [Bear Tech logo]": the company credit under splash, welcome and
/// Home. [caption] adds a line under it (e.g. the version).
class BearTechCredit extends StatelessWidget {
  const BearTechCredit({super.key, this.onDark = false, this.caption, this.logoHeight = 30});

  final bool onDark;
  final String? caption;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = onDark ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      label: 'from ${AppConstants.company}${caption == null ? '' : ', $caption'}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('from', style: text.labelSmall?.copyWith(color: muted, letterSpacing: 0.6)),
          const SizedBox(height: AppSpacing.xs),
          BearTechLogo(height: logoHeight, onDark: onDark),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(caption!, style: text.labelSmall?.copyWith(color: muted)),
          ],
        ],
      ),
    );
  }
}
