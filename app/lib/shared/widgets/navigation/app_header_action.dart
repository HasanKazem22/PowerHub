import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';

/// Round header button on a light disc (back, bell, settings): a compact 36px disc that
/// stays easy to press, because the tap area around it is 44px.
class AppHeaderAction extends StatelessWidget {
  const AppHeaderAction({super.key, required this.icon, required this.onPressed, this.tooltip, this.badge = false});

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  /// Small red dot (e.g. unread notifications).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: AppSpacing.headerActionTap,
      child: Center(
        child: SizedBox.square(
          dimension: AppSpacing.headerAction,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [context.palette.headerAction, context.palette.cardSheenEnd],
              ),
              border: Border.all(color: context.palette.cardEdge, width: 0.8),
              boxShadow: context.isDark ? null : AppShadows.headerAction,
            ),
            child: IconButton(
              tooltip: tooltip,
              padding: EdgeInsets.zero,
              // The whole 44px square responds, not only the disc.
              style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.padded),
              constraints: const BoxConstraints.tightFor(
                width: AppSpacing.headerActionTap,
                height: AppSpacing.headerActionTap,
              ),
              onPressed: onPressed,
              icon: Badge(
                isLabelVisible: badge,
                smallSize: 7,
                child: Icon(icon, color: scheme.primary, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
