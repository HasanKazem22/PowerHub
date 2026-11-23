import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Coloured icon on a round disc: service tiles, list rows, stat cards and
/// menus all use it, so icons look the same everywhere.
///
/// By default the disc is a neutral light grey and only the icon carries the
/// colour, which keeps a screen full of icons calm. Set [tinted] for a disc in
/// a soft shade of [color] instead (status-style emphasis).
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({super.key, required this.icon, required this.color, this.size = 44, this.tinted = false});

  final IconData icon;
  final Color color;
  final double size;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tinted ? color.withValues(alpha: 0.14) : null,
        // Glossy disc: lighter at the top, like light falling on it.
        gradient: tinted
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [context.palette.iconCircleSheen, context.palette.iconCircle],
              ),
        border: tinted ? null : Border.all(color: context.palette.cardEdge, width: 0.8),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
