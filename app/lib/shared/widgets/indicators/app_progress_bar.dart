import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Rounded progress bar on a soft track. [value] is 0..1.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, this.color, this.trackColor, this.height = 8});
  final double value;
  final Color? color;
  final Color? trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        color: color,
        backgroundColor: trackColor ?? Theme.of(context).colorScheme.surfaceContainer,
      ),
    );
  }
}
