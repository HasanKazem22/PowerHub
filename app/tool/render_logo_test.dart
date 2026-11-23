// Renders the PowerHub logo (the full name) to the PNG files used for the launcher icons.
// Run from app/:  flutter test tool/render_logo_test.dart
// then:           dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/core/theme/app_colors.dart';
import 'package:powerhub/core/theme/app_theme.dart';
import 'package:powerhub/shared/widgets/branding/app_logo.dart';

/// Brand-blue icon background, same as the hero cards.
const _iconGradient = [AppColors.primaryDark, AppColors.primary, AppColors.brand];

Future<void> _render(
  String path, {
  required double logoFraction,
  bool onDark = false,
  bool blueBackground = false,
}) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (blueBackground) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, size, size),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _iconGradient,
        ).createShader(const Rect.fromLTWH(0, 0, size, size)),
    );
  }
  final logo = size * logoFraction;
  canvas.translate((size - logo) / 2, (size - logo) / 2);
  AppLogoPainter(onDark: onDark).paint(canvas, Size.square(logo));
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render logo PNGs', (tester) async {
    await tester.runAsync(() async {
      // The logo is lettering, so the real font must be loaded.
      final loader = FontLoader(appFontFamily);
      for (final w in ['Light', 'Bold']) {
        loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Ubuntu-$w.ttf').readAsBytesSync())));
      }
      await loader.load();

      Directory('assets/images').createSync(recursive: true);
      // Plain logo (blue Power, amber Hub), transparent background.
      await _render('assets/images/logo.png', logoFraction: 1);
      // iOS / legacy Android / web icon: brand-blue square, white Power + amber Hub.
      await _render('assets/images/app_icon.png', logoFraction: 0.78, onDark: true, blueBackground: true);
      // Android adaptive icon foreground (background colour set in pubspec):
      // the name inside the safe circle (66 % of the icon), which launchers never crop.
      await _render('assets/images/app_icon_foreground.png', logoFraction: 0.56, onDark: true);
    });
  });
}
