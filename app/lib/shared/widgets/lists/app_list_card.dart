import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../cards/app_card.dart';

/// A white card holding list rows ([AppListTile]s), with hairline dividers
/// that start after the icon column.
class AppListCard extends StatelessWidget {
  const AppListCard({super.key, required this.children, this.dividerIndent = _iconColumn});

  final List<Widget> children;

  /// Left inset of the dividers. Defaults to the width of the icon column.
  final double dividerIndent;

  static const _iconColumn = AppSpacing.lg + AppSpacing.listIcon + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: dividerIndent, endIndent: AppSpacing.lg),
            children[i],
          ],
        ],
      ),
    );
  }
}
