import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../buttons/app_pill_button.dart';
import 'app_gradient_card.dart';

/// Compact gradient strip: what it is on the left, one gold action on the
/// right ("Plan your purchases · Plan now").
class AppHeroCard extends StatelessWidget {
  const AppHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon = Icons.arrow_forward_rounded,
    this.colors = AppGradientCard.brandGradient,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      colors: colors,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AppPillButton(label: actionLabel, icon: actionIcon, onPressed: onAction),
        ],
      ),
    );
  }
}
