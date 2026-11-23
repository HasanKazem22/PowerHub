import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The icons of the bottom navigation bar.
enum AppNavGlyphKind { home, history, add, guide, settings }

/// A bottom-bar icon drawn in code, in an outline and a filled form (same
/// icon class as the other Bear Tech apps).
///
/// Drawn rather than taken from the Material set for two reasons. Material's
/// icons vary in stroke weight from one glyph to the next, which reads as
/// generic when five sit in a row; these share one rounded stroke. And
/// Material's filled icons fill the whole shape, losing the inner detail; here
/// the filled form keeps its detail as a white line, so the active tab is
/// solid without becoming a blob.
///
/// Every shape is laid out on a 24-unit grid and scaled to [size].
class AppNavGlyph extends StatelessWidget {
  const AppNavGlyph({super.key, required this.kind, required this.color, this.filled = false, this.size = 26});

  final AppNavGlyphKind kind;
  final Color color;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _AppNavGlyphPainter(kind: kind, color: color, filled: filled),
      ),
    );
  }
}

class _AppNavGlyphPainter extends CustomPainter {
  _AppNavGlyphPainter({required this.kind, required this.color, required this.filled});

  final AppNavGlyphKind kind;
  final Color color;
  final bool filled;

  static const double _stroke = 1.9;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    // Inner detail on a filled glyph: the white cut-through.
    final detail = Paint()
      ..color = filled ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    /// A closed body: filled when active, outlined otherwise. The stroke is
    /// drawn in both cases so the filled corners are as round as the outline.
    void body(Path path) {
      if (filled) canvas.drawPath(path, fill);
      canvas.drawPath(path, line);
    }

    switch (kind) {
      case AppNavGlyphKind.home:
        final house = Path()
          ..moveTo(3.8, 10.4)
          ..lineTo(12, 3.9)
          ..lineTo(20.2, 10.4)
          ..lineTo(20.2, 18.4)
          ..arcToPoint(const Offset(18.1, 20.5), radius: const Radius.circular(2.1))
          ..lineTo(5.9, 20.5)
          ..arcToPoint(const Offset(3.8, 18.4), radius: const Radius.circular(2.1))
          ..close();
        body(house);
        canvas.drawLine(const Offset(9.8, 16.4), const Offset(14.2, 16.4), detail);

      case AppNavGlyphKind.history:
        // A project folder.
        final folder = Path()
          ..moveTo(3.6, 7.4)
          ..arcToPoint(const Offset(5.6, 5.2), radius: const Radius.circular(2))
          ..lineTo(9.2, 5.2)
          ..lineTo(11.2, 7.2)
          ..lineTo(18.4, 7.2)
          ..arcToPoint(const Offset(20.4, 9.2), radius: const Radius.circular(2))
          ..lineTo(20.4, 17.8)
          ..arcToPoint(const Offset(18.4, 19.8), radius: const Radius.circular(2))
          ..lineTo(5.6, 19.8)
          ..arcToPoint(const Offset(3.6, 17.8), radius: const Radius.circular(2))
          ..close();
        body(folder);
        canvas.drawLine(const Offset(9.4, 14.2), const Offset(14.6, 14.2), detail);

      case AppNavGlyphKind.add:
        // A plus in a rounded square.
        body(Path()..addRRect(RRect.fromLTRBR(3.8, 3.8, 20.2, 20.2, const Radius.circular(5))));
        canvas.drawLine(const Offset(12, 8.4), const Offset(12, 15.6), detail);
        canvas.drawLine(const Offset(8.4, 12), const Offset(15.6, 12), detail);

      case AppNavGlyphKind.guide:
        // A safety shield with a lightning bolt: the fault and safety guide.
        final shield = Path()
          ..moveTo(12, 3)
          ..lineTo(19.2, 5.9)
          ..lineTo(19.2, 11.2)
          ..cubicTo(19.2, 15.7, 16.2, 19.3, 12, 21)
          ..cubicTo(7.8, 19.3, 4.8, 15.7, 4.8, 11.2)
          ..lineTo(4.8, 5.9)
          ..close();
        body(shield);
        final bolt = Path()
          ..moveTo(12.9, 7.2)
          ..lineTo(9.7, 12.5)
          ..lineTo(12.1, 12.5)
          ..lineTo(11.1, 16.8)
          ..lineTo(14.3, 11.4)
          ..lineTo(11.9, 11.4)
          ..close();
        canvas.drawPath(bolt, detail);

      case AppNavGlyphKind.settings:
        // A gear with eight rounded teeth and a hub.
        final gear = Path();
        const teeth = 8;
        for (var i = 0; i < teeth * 2; i++) {
          final a = i * math.pi / teeth - math.pi / 2;
          final r = i.isEven ? 8.6 : 6.6;
          for (final da in [-0.17, 0.17]) {
            final p = Offset(12 + r * math.cos(a + da), 12 + r * math.sin(a + da));
            if (i == 0 && da < 0) {
              gear.moveTo(p.dx, p.dy);
            } else {
              gear.lineTo(p.dx, p.dy);
            }
          }
        }
        gear.close();
        body(gear);
        canvas.drawCircle(const Offset(12, 12), 2.6, detail);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_AppNavGlyphPainter old) => old.kind != kind || old.color != color || old.filled != filled;
}
