import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'app_field_label.dart';

/// Pick one of a few options (up to about 5) as chips, all visible at once: account type, which account, … The same
/// chip look as the category picker. Longer lists use [AppPickerField] + `showAppChoiceSheet` instead.
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.itemLabel,
    required this.onChanged,
    this.itemIcon,
    this.itemColor,
    this.footer,
  });

  final String label;
  final List<T> items;
  final T? value;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final IconData Function(T)? itemIcon;
  final Color Function(T)? itemColor;

  /// Small text under the chips (a hint, the chosen account's balance, an error).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFieldLabel(label),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final item in items)
              ChoiceChip(
                avatar: itemIcon == null ? null : Icon(itemIcon!(item), size: 18, color: itemColor?.call(item)),
                label: Text(itemLabel(item)),
                selected: item == value,
                onSelected: (_) => onChanged(item),
              ),
          ],
        ),
        if (footer != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs),
            child: footer,
          ),
        ],
      ],
    );
  }
}
