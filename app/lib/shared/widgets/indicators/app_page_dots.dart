import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Page indicator for swipeable pages: a dot per page, the current one
/// stretched into a brand-green pill.
class AppPageDots extends StatelessWidget {
  const AppPageDots({super.key, required this.count, required this.index, this.onTap});

  final int count;
  final int index;

  /// Jump to a page when its dot is tapped.
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap == null ? null : () => onTap!(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: i == index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == index ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
