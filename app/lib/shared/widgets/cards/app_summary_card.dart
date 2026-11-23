import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../buttons/app_pill_button.dart';
import 'app_gradient_card.dart';

/// One figure in the bottom panel of [AppSummaryCard].
class AppSummaryMetric {
  const AppSummaryMetric(this.label, this.value, {this.icon, this.accent});
  final String label;

  /// The figure as shown ("415 A", "2 × 630 kVA").
  final String value;
  final IconData? icon;

  /// Colour of the icon (on the dark gradient). Defaults to white.
  final Color? accent;
}

/// The page hero: the brand gradient with a small caps label, one big value,
/// an optional gold action pill, an optional progress bar, and up to three
/// smaller figures on a frosted panel underneath.
///
/// Home shows the saved-projects overview with it; each calculator shows its
/// headline result (transformer size, kWp, …) with it.
class AppSummaryCard extends StatelessWidget {
  const AppSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.actionLabel,
    this.actionIcon = Icons.add_rounded,
    this.onAction,
    this.progress,
    this.progressLabel,
    this.metrics = const [],
  });

  /// Shown in small caps above the amount ("TOTAL BALANCE").
  final String label;

  /// The big figure as shown ("2 × 630 kVA").
  final String value;

  /// Small line under the value ("Loading 72 %").
  final String? caption;

  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  /// 0..1, drawn as a thin bar under the amount.
  final double? progress;

  /// Caption next to the progress bar ("2 of 5 bought").
  final String? progressLabel;
  final List<AppSummaryMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Color white(double a) => Colors.white.withValues(alpha: a);

    return AppGradientCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(color: white(0.8), letterSpacing: 1),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: text.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (caption != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(caption!, style: text.bodySmall?.copyWith(color: white(0.85))),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: AppSpacing.md),
                AppPillButton(label: actionLabel!, leadingIcon: actionIcon, onPressed: onAction),
              ],
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: white(0.18),
                      color: AppColors.gold,
                    ),
                  ),
                ),
                if (progressLabel != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  Text(progressLabel!, style: text.labelSmall?.copyWith(color: white(0.85))),
                ],
              ],
            ),
          ],
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: white(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: white(0.10)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      if (i > 0) VerticalDivider(width: 1, thickness: 1, color: white(0.16)),
                      Expanded(child: _Metric(metrics[i])),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.metric);
  final AppSummaryMetric metric;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (metric.icon != null) ...[
                Icon(metric.icon, size: 14, color: metric.accent ?? Colors.white),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              style: text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
