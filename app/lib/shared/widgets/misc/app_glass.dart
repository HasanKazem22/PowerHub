import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_gloss.dart';
import '../../../core/theme/app_palette.dart';

enum AppGlassEdge { top, bottom }

/// Frosted glass: content behind is blurred and shows through a translucent
/// fill, with a thin light line on [edge]. Used for the top and bottom bars.
class AppGlass extends StatelessWidget {
  const AppGlass({super.key, required this.child, this.edge = AppGlassEdge.top, this.shadow = true});

  final Widget child;

  /// Which side gets the light edge line (the side facing the content).
  final AppGlassEdge edge;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final line = BorderSide(color: palette.glassEdge);
    return DecoratedBox(
      // The shadow sits outside the clip, so the blur doesn't cut it off.
      decoration: BoxDecoration(
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: Offset(0, edge == AppGlassEdge.top ? -2 : 2),
                ),
              ]
            : null,
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AppGloss.blur, sigmaY: AppGloss.blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.glass,
              border: edge == AppGlassEdge.top ? Border(top: line) : Border(bottom: line),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
