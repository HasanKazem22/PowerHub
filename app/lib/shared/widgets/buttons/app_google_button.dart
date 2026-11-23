import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// "Continue with Google": white button with the four-colour G, following
/// Google's sign-in button guidelines (white fill, grey outline, dark text).
class AppGoogleButton extends StatelessWidget {
  const AppGoogleButton({super.key, required this.onPressed, this.label = 'Continue with Google', this.busy = false});

  final VoidCallback? onPressed;
  final String label;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonMedium,
      child: OutlinedButton(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: context.palette.card,
          foregroundColor: const Color(0xFF1F1F1F),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            else
              const GoogleLogo(size: 18),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: const TextStyle(fontFamily: appFontFamily, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google's "G", drawn so no image asset is needed.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 18});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: const CustomPaint(painter: _GoogleLogoPainter()),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  // Google brand colours (only used inside the logo).
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double rad(double deg) => deg * math.pi / 180;

    // Clockwise from 3 o'clock; the opening of the G is at the upper right.
    canvas.drawArc(rect, rad(0), rad(45), false, arc(_blue));
    canvas.drawArc(rect, rad(45), rad(90), false, arc(_green));
    canvas.drawArc(rect, rad(135), rad(80), false, arc(_yellow));
    canvas.drawArc(rect, rad(215), rad(100), false, arc(_red));
    // The bar.
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, size.height / 2 - stroke / 2, size.width / 2, stroke),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
