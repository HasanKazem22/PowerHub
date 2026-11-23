import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// One "Label ........ value" line of [SummaryLines].
class SummaryLine {
  const SummaryLine(this.label, this.value, {this.valueColor, this.bold = false});
  final String label;
  final String value;
  final Color? valueColor;

  /// Emphasise the line (e.g. the total).
  final bool bold;
}

/// Label/value lines in a soft panel, for details sheets (a loan's amounts
/// and dates, …).
class SummaryLines extends StatelessWidget {
  const SummaryLines({super.key, required this.lines});
  final List<SummaryLine> lines;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.label, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      line.value,
                      textAlign: TextAlign.end,
                      style: (line.bold ? text.titleSmall : text.bodyMedium)?.copyWith(
                        color: line.valueColor,
                        fontWeight: line.bold ? FontWeight.w700 : FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
