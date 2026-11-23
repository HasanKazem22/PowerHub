import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// The app's one list row: leading icon disc, title and subtitle, and a
/// trailing value with an optional caption under it.
///
/// Projects, units, settings and menu options all use it, so
/// every list has the same height, padding and type.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.trailingCaption,
    this.onTap,
    this.titleStyle,
    this.subtitleMaxLines = 1,
  });

  /// Usually an [AppIconBadge] of size [AppSpacing.listIcon].
  final Widget? leading;
  final String title;
  final String? subtitle;

  /// Replaces [subtitle] (e.g. a status badge and a note).
  final Widget? subtitleWidget;

  /// Usually an [AmountText] or a chevron.
  final Widget? trailing;

  /// Small text under [trailing] ("MCCB").
  final String? trailingCaption;
  final VoidCallback? onTap;
  final TextStyle? titleStyle;

  /// Lines of [subtitle] before it is cut off (1 for lists; more for explanations, e.g. menu options).
  final int subtitleMaxLines;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.md)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600).merge(titleStyle),
                  ),
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    subtitleWidget!,
                  ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle!,
                      maxLines: subtitleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.md),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  trailing!,
                  if (trailingCaption != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(trailingCaption!, style: text.labelSmall?.copyWith(color: muted)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
