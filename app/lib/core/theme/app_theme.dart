import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_spacing.dart';

/// Bundled Google font (see pubspec.yaml).
const appFontFamily = 'Ubuntu';

/// Used for characters Ubuntu does not have: Bangla (the fault guide, project names).
const appFontFallback = ['NotoSansBengali'];

/// Builds ThemeData from the tokens. Every stock Material component (buttons,
/// fields, dialogs, sheets, chips, snackbars) takes its look from here, so
/// screens stay consistent without restating styles.
///
/// The direction: soft rounded shapes, filled fields instead of boxed
/// outlines, white cards on an off-white page separated by a faint shadow, and
/// the brand blue used sparingly for what can be tapped.
abstract final class AppTheme {
  /// Fully transparent system bars so the page colour runs up behind them
  /// (edge-to-edge) instead of a grey scrim, with dark icons on light pages.
  static const lightOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android
    statusBarBrightness: Brightness.light, // iOS
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );

  static const darkOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: AppColors.onBrand,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.gold,
      onSecondary: AppColors.onGold,
      secondaryContainer: AppColors.primarySoft,
      onSecondaryContainer: AppColors.primary,
      error: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHigh,
      // No tint: Material 3 washes elevated surfaces in the primary colour.
      surfaceTint: Colors.transparent,
    );
    return _build(
      scheme: scheme,
      background: AppColors.background,
      fieldFill: AppColors.fieldFill,
      palette: AppPalette.light,
      overlay: lightOverlay,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.dark,
    ).copyWith(surfaceTint: Colors.transparent);
    return _build(
      scheme: scheme,
      background: scheme.surface,
      fieldFill: scheme.surfaceContainerHigh,
      palette: AppPalette.dark(scheme),
      overlay: darkOverlay,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required Color fieldFill,
    required AppPalette palette,
    required SystemUiOverlayStyle overlay,
  }) {
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
    const buttonText = TextStyle(fontFamily: appFontFamily, fontSize: 14, fontWeight: FontWeight.w600);

    OutlineInputBorder fieldBorder(Color? color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: color == null ? BorderSide.none : BorderSide(color: color, width: width),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      fontFamily: appFontFamily,
      fontFamilyFallback: appFontFallback,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      extensions: [palette],

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlay,
        titleTextStyle: TextStyle(
          fontFamily: appFontFamily,
          fontFamilyFallback: appFontFallback,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),

      // ── Buttons ─────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.buttonHeight),
          shape: rounded,
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.buttonHeight),
          shape: rounded,
          textStyle: buttonText,
          foregroundColor: scheme.primary,
          backgroundColor: palette.card,
          side: BorderSide(color: scheme.outlineVariant, width: 1.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary, textStyle: buttonText, shape: rounded),
      ),

      // ── Text fields: filled, no resting border, brand outline on focus ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: fieldBorder(null),
        enabledBorder: fieldBorder(null),
        disabledBorder: fieldBorder(null),
        focusedBorder: fieldBorder(scheme.primary, 1.6),
        errorBorder: fieldBorder(scheme.error, 1.2),
        focusedErrorBorder: fieldBorder(scheme.error, 1.6),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: scheme.outline),
        prefixIconColor: scheme.outline,
        suffixIconColor: scheme.outline,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.2),
        selectionHandleColor: scheme.primary,
      ),

      // ── Chips, segmented buttons ─────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: fieldFill,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          fontFamily: appFontFamily,
          fontFamilyFallback: appFontFallback,
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: appFontFamily,
          fontFamilyFallback: appFontFallback,
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: fieldFill,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide.none,
          shape: rounded,
          textStyle: const TextStyle(fontFamily: appFontFamily, fontWeight: FontWeight.w500),
        ).copyWith(visualDensity: VisualDensity.standard),
      ),

      // ── Sheets, dialogs, snackbars ──────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.panel))),
      ),
      // Date picker: same warm card, rounded corners and brand green as the app's sheets.
      datePickerTheme: DatePickerThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        headerBackgroundColor: scheme.primary,
        headerForegroundColor: scheme.onPrimary,
        dividerColor: Colors.transparent,
        todayBorder: BorderSide(color: scheme.primary, width: 1.2),
        dayShape: const WidgetStatePropertyAll(CircleBorder()),
        confirmButtonStyle: TextButton.styleFrom(textStyle: buttonText),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant, textStyle: buttonText),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg)),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5), space: 1),
    );
  }
}
