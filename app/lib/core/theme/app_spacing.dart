import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing scale (logical pixels). Use these instead of raw numbers.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Side padding of every page.
  static const double page = lg;

  /// Button heights. Medium is the default everywhere (forms, sheets, page
  /// actions); small is for inline actions (empty states, banners); large is
  /// kept for rare hero actions.
  static const double buttonSmall = 36;
  static const double buttonMedium = 44;
  static const double buttonLarge = 50;

  /// Height of the default (medium) button.
  static const double buttonHeight = buttonMedium;

  /// Leading icon disc in list rows.
  static const double listIcon = 42;

  /// Round header buttons (back, bell, settings): the visible disc. The tap area is larger ([headerActionTap]).
  static const double headerAction = 36;

  /// Tap area around a header button, so a small disc is still easy to press.
  static const double headerActionTap = 44;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;

  /// Large panels (the quick-action grid).
  static const double panel = 24;
  static const double pill = 999;
  static const double navBar = 20;
  static const BorderRadius navBarTop = BorderRadius.vertical(top: Radius.circular(navBar));
}

abstract final class AppShadows {
  /// Soft, slightly lifted shadow for white cards on the off-white page.
  static List<BoxShadow> card(Color color) => [
    BoxShadow(color: color, blurRadius: 18, spreadRadius: -4, offset: const Offset(0, 6)),
  ];

  /// Coloured glow under gradient hero cards.
  static List<BoxShadow> hero(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 16, spreadRadius: -6, offset: const Offset(0, 10)),
  ];

  /// Round header buttons.
  static final List<BoxShadow> headerAction = [
    BoxShadow(color: AppColors.primary.withValues(alpha: 0.07), blurRadius: 6, offset: const Offset(0, 2)),
  ];

  /// Small pills ("See more").
  static final List<BoxShadow> pill = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 3)),
  ];

  static const List<BoxShadow> bottomBar = [
    BoxShadow(color: AppColors.shadowSoft, blurRadius: 10, offset: Offset(0, -2)),
  ];

  /// Logo disc on the off-white splash: a soft, brand-tinted lift.
  static final List<BoxShadow> logoSoft = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.12),
      blurRadius: 32,
      spreadRadius: -4,
      offset: const Offset(0, 12),
    ),
  ];

  static final List<BoxShadow> logo = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 10)),
  ];
}
