import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../indicators/app_icon_badge.dart';

/// Data for one tile in an [AppIconGrid].
class AppIconTileData {
  const AppIconTileData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  /// Seen but not usable yet (shown faded; [onTap] still runs, e.g. to explain why).
  final bool enabled;
}

/// Coloured icon on a grey disc with a two-line label underneath.
class AppIconTile extends StatelessWidget {
  const AppIconTile({super.key, required this.data});
  final AppIconTileData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: data.label,
      excludeSemantics: true,
      child: Opacity(
        opacity: data.enabled ? 1 : 0.45,
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.xxs),
            child: Column(
              children: [
                AppIconBadge(icon: data.icon, color: data.color, size: 54),
                const SizedBox(height: AppSpacing.sm),
                // A fixed two-line box, so a long label can't push its row out of line.
                SizedBox(
                  height: 32,
                  child: Text(
                    data.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
