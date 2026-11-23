import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The PowerHub logo: the full name, "Power" bold in glossy electric blue and "Hub" light in glossy spark amber. It is the name
/// itself, so never put the name as text next to it. Use it wherever the brand appears (splash, Home's title,
/// welcome screen). [onDark]: white "Power" and light amber "Hub" for blue backgrounds.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 28, this.onDark = false});

  /// Height of the letters (the font size).
  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    TextStyle style(FontWeight weight) => TextStyle(
      fontFamily: appFontFamily,
      fontSize: height,
      height: 1.1,
      fontWeight: weight,
      letterSpacing: -height * 0.012,
      color: Colors.white, // Replaced by the gradient (ShaderMask).
    );

    Widget part(String text, FontWeight weight, List<Color> colors) => ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors).createShader(bounds),
      child: Text(text, style: style(weight)),
    );

    return Semantics(
      label: 'PowerHub',
      image: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            part(
              'Power',
              FontWeight.w700,
              onDark ? const [Colors.white, Colors.white] : const [AppLogoColors.blueLight, AppLogoColors.blue],
            ),
            part(
              'Hub',
              FontWeight.w300,
              onDark
                  ? const [AppLogoColors.goldLight, AppLogoColors.goldLight]
                  : const [AppLogoColors.gold, AppLogoColors.goldDeep],
            ),
          ],
        ),
      ),
    );
  }
}

/// App bar title on Home: the logo.
class AppLogoTitle extends StatelessWidget {
  const AppLogoTitle({super.key});

  @override
  Widget build(BuildContext context) => const AppLogo(height: 26);
}

class AppLogoColors {
  AppLogoColors._();
  static const blueLight = Color(0xFF3B82F6);
  static const blue = Color(0xFF1656D6);
  static const blueDeep = Color(0xFF0A2A6B);
  static const goldLight = Color(0xFFFFD23F);
  static const gold = Color(0xFFF5A10F);
  static const goldDeep = Color(0xFFC76A00);
}

/// Paints the [AppLogo] ("PowerHub") centred in [Size], as large as fits. Used by tool/render_logo_test.dart for
/// the launcher icons, so the icon and the in-app logo are the same.
class AppLogoPainter extends CustomPainter {
  const AppLogoPainter({this.onDark = false});
  final bool onDark;

  TextPainter _layout(double fontSize, Rect rect) {
    Paint fill(List<Color> colors) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect);

    return TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        style: TextStyle(fontFamily: appFontFamily, fontSize: fontSize, height: 1, letterSpacing: -fontSize * 0.012),
        children: [
          TextSpan(
            text: 'Power',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              foreground: onDark
                  ? (Paint()..color = Colors.white)
                  : fill(const [AppLogoColors.blueLight, AppLogoColors.blue]),
            ),
          ),
          TextSpan(
            text: 'Hub',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              foreground: onDark
                  ? (Paint()..color = AppLogoColors.goldLight)
                  : fill(const [AppLogoColors.gold, AppLogoColors.goldDeep]),
            ),
          ),
        ],
      ),
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Measure once, then scale the font so the name fills the width (or the height, if that is smaller).
    final probe = _layout(100, rect);
    final fontSize = 100 * (size.width / probe.width).clamp(0.0, size.height / 100);
    final painter = _layout(fontSize, rect);
    // Centre on the visible letters: from the top of the capitals (about 0.7 em above the baseline) to the baseline.
    final baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final capHeight = fontSize * 0.70;
    painter.paint(canvas, Offset((size.width - painter.width) / 2, (size.height + capHeight) / 2 - baseline));
  }

  @override
  bool shouldRepaint(AppLogoPainter oldDelegate) => oldDelegate.onDark != onDark;
}
