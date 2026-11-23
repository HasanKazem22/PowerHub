import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The glossy finish used across the app, in one place:
/// frosted glass for bars, a soft sheen on cards, buttons and discs.
abstract final class AppGloss {
  /// Blur behind frosted-glass bars.
  static const double blur = 20;

  /// Light falling on the top of a coloured surface (gradient cards, buttons,
  /// gold pills): white fading out by the middle.
  static LinearGradient sheen({double strength = 0.18}) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.center,
    colors: [
      Colors.white.withValues(alpha: strength),
      Colors.white.withValues(alpha: 0),
    ],
  );

  /// Glossy brand-blue fill for primary buttons and the active "+".
  static const LinearGradient brandButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.brandGlossTop, AppColors.brand, AppColors.primary],
    stops: [0, 0.55, 1],
  );

  /// Glossy amber fill for pill actions.
  static const LinearGradient goldButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.goldGlossTop, AppColors.gold, AppColors.goldGlossBottom],
    stops: [0, 0.55, 1],
  );
}
