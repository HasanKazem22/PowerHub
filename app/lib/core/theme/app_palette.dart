import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colours that change between light and dark mode but are not part of
/// Material's ColorScheme, including the glossy surfaces. Read with
/// `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.card,
    required this.cardSheenEnd,
    required this.cardEdge,
    required this.iconCircle,
    required this.iconCircleSheen,
    required this.cardShadow,
    required this.headerAction,
    required this.glass,
    required this.glassEdge,
  });

  /// Background of cards and panels (top of their glossy gradient).
  final Color card;

  /// Bottom of the card's glossy gradient.
  final Color cardSheenEnd;

  /// Hairline highlight along a card's edge.
  final Color cardEdge;

  /// Disc behind service and list icons, and the lighter top of its gloss.
  final Color iconCircle;
  final Color iconCircleSheen;

  /// Shadow under cards (transparent in dark mode, where shadows don't show).
  final Color cardShadow;

  /// Disc behind round header buttons.
  final Color headerAction;

  /// Frosted-glass fill of the top and bottom bars, and its edge line.
  final Color glass;
  final Color glassEdge;

  static const light = AppPalette(
    card: AppColors.surface,
    cardSheenEnd: AppColors.cardSheenEnd,
    cardEdge: AppColors.cardEdge,
    iconCircle: AppColors.iconCircle,
    iconCircleSheen: AppColors.iconCircleSheen,
    cardShadow: AppColors.cardShadow,
    headerAction: AppColors.surface,
    glass: AppColors.glass,
    glassEdge: AppColors.glassEdge,
  );

  static AppPalette dark(ColorScheme scheme) => AppPalette(
    card: scheme.surfaceContainerHigh,
    cardSheenEnd: scheme.surfaceContainer,
    cardEdge: Colors.white.withValues(alpha: 0.06),
    iconCircle: scheme.surfaceContainerHighest,
    iconCircleSheen: Color.lerp(scheme.surfaceContainerHighest, Colors.white, 0.08)!,
    cardShadow: Colors.transparent,
    headerAction: scheme.surfaceContainerHigh,
    glass: scheme.surface.withValues(alpha: 0.78),
    glassEdge: Colors.white.withValues(alpha: 0.06),
  );

  @override
  AppPalette copyWith({
    Color? card,
    Color? cardSheenEnd,
    Color? cardEdge,
    Color? iconCircle,
    Color? iconCircleSheen,
    Color? cardShadow,
    Color? headerAction,
    Color? glass,
    Color? glassEdge,
  }) => AppPalette(
    card: card ?? this.card,
    cardSheenEnd: cardSheenEnd ?? this.cardSheenEnd,
    cardEdge: cardEdge ?? this.cardEdge,
    iconCircle: iconCircle ?? this.iconCircle,
    iconCircleSheen: iconCircleSheen ?? this.iconCircleSheen,
    cardShadow: cardShadow ?? this.cardShadow,
    headerAction: headerAction ?? this.headerAction,
    glass: glass ?? this.glass,
    glassEdge: glassEdge ?? this.glassEdge,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      card: l(card, other.card),
      cardSheenEnd: l(cardSheenEnd, other.cardSheenEnd),
      cardEdge: l(cardEdge, other.cardEdge),
      iconCircle: l(iconCircle, other.iconCircle),
      iconCircleSheen: l(iconCircleSheen, other.iconCircleSheen),
      cardShadow: l(cardShadow, other.cardShadow),
      headerAction: l(headerAction, other.headerAction),
      glass: l(glass, other.glass),
      glassEdge: l(glassEdge, other.glassEdge),
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
