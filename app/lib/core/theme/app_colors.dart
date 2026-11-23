import 'package:flutter/material.dart';

/// All colour tokens for PowerHub. Source: the logo, an electric-blue bolt
/// (#3B82F6 deepening to #0A2A6B) with a spark-amber flash (#FFD23F deepening to #C76A00).
/// RULE: don't write Color(0xFF...) in screens or widgets; add a token here.
///
/// The token names follow the shared Bear Tech design kit (brand + gold), so
/// every shared widget works unchanged: in PowerHub "brand" is electric blue
/// and "gold" is spark amber.
abstract final class AppColors {
  // ── Brand blue ──────────────────────────────────────────────────
  /// Deep brand blue: hero gradients, pressed states.
  static const Color primary = Color(0xFF0B3B8C);

  /// Signature electric blue: buttons, the "+" button, active tabs, focused fields.
  static const Color brand = Color(0xFF1656D6);
  static const Color onBrand = Color(0xFFFFFFFF);

  /// Darkest logo blue, start of hero gradients.
  static const Color primaryDark = Color(0xFF071E4A);

  /// Very light blue: tonal buttons, selected chips.
  static const Color primarySoft = Color(0xFFE1EAFC);

  // ── Spark amber (the logo's second colour) ─────────────────────
  static const Color gold = Color(0xFFFFB627);
  static const Color onGold = Color(0xFF2A1A00);
  static const Color goldLight = Color(0xFFFFD23F);

  // ── Surfaces (light) ────────────────────────────────────────────
  /// Page background: a cool off-white, so white cards stand out.
  static const Color background = Color(0xFFF7F8FC);

  /// Cards, sheets, dialogs, round buttons: a shade lighter than the page,
  /// never pure white (#FFFFFF).
  static const Color surface = Color(0xFFFDFDFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F9);
  static const Color surfaceContainer = Color(0xFFECEFF6);
  static const Color surfaceContainerHigh = Color(0xFFE5E9F2);
  static const Color onSurface = Color(0xFF161A23);
  static const Color onSurfaceVariant = Color(0xFF454B58);
  static const Color outline = Color(0xFF737A88);
  static const Color outlineVariant = Color(0xFFC8CEDA);

  /// Fill of text fields: cool light grey.
  static const Color fieldFill = Color(0xFFF1F3F8);

  /// Grey disc behind service and list icons, and the lighter top of its gloss.
  static const Color iconCircle = Color(0xFFEFF2F8);
  static const Color iconCircleSheen = Color(0xFFFAFBFE);

  /// Frosted bars: the page colour at 85 %, and its top edge line.
  static const Color glass = Color(0xD9F7F8FC);
  static const Color glassEdge = Color(0xFFE6EAF2);

  /// Bottom of the glossy card gradient (top is white).
  static const Color cardSheenEnd = Color(0xFFF6F8FC);

  /// Hairline edge around cards and round buttons.
  static const Color cardEdge = Color(0xFFE9EDF4);

  /// Splash background (deep logo blue).
  static const Color splash = Color(0xFF0A2F73);

  // ── Meaning ─────────────────────────────────────────────────────
  static const Color ok = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEA580C);
  static const Color neutral = Color(0xFF64748B);
  static const Color error = Color(0xFFBA1A1A);

  // ── Banners (soft tinted panels) ────────────────────────────────
  static const Color infoContainer = Color(0xFFE6F0FB);
  static const Color infoText = Color(0xFF0E4A7A);
  static const Color warningContainer = Color(0xFFFFF4E0);
  static const Color warningText = Color(0xFF8A5A00);
  static const Color errorContainer = Color(0xFFFDECEC);
  static const Color successContainer = Color(0xFFE7F4EC);
  static const Color successText = Color(0xFF1B6B3A);

  // ── Calculator / quick-action icon colours ──────────────────────
  /// Mid-tone, slightly muted, so a grid of coloured icons reads as friendly.
  static const Color tileRose = Color(0xFFE0607A);
  static const Color tileGreen = Color(0xFF2F9468);
  static const Color tileOrange = Color(0xFFEF8A3C);
  static const Color tilePurple = Color(0xFF8B5CD6);
  static const Color tileSlate = Color(0xFF5B6B85);
  static const Color tilePink = Color(0xFFCC4A93);
  static const Color tileBlue = Color(0xFF2F6FD6);
  static const Color tileTeal = Color(0xFF138A93);
  static const Color tileRed = Color(0xFFD9485F);
  static const Color tileAmber = Color(0xFFD99A06);

  // ── Shadows ─────────────────────────────────────────────────────
  static const Color shadow = Color(0x42000000);

  /// Very soft navy-tinted shadow for the bottom bar.
  static const Color shadowSoft = Color(0x0F021F51);

  /// Brand blue at 7 %: the soft lift under cards.
  static const Color cardShadow = Color(0x120B3B8C);

  /// Inactive bottom-bar icon and label.
  static const Color navInactive = Color(0xFF5B6270);

  // ── Gloss stops (see app_gloss.dart) ────────────────────────────
  static const Color brandGlossTop = Color(0xFF3B7BEA);
  static const Color goldGlossTop = Color(0xFFFFD36B);
  static const Color goldGlossBottom = Color(0xFFF29E12);
  static const Color goldDeep = Color(0xFF7A4A00);
  static const Color goldMid = Color(0xFFC77700);
}
