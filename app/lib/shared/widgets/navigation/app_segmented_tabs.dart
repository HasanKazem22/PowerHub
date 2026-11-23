import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';

/// One option of [AppSegmentedTabs].
class AppTabItem<T> {
  const AppTabItem(this.value, this.label, {this.icon, this.color});
  final T value;
  final String label;
  final IconData? icon;

  /// Colour of the label and icon when selected. Defaults to the brand colour
  /// (e.g. a calculator's colour).
  final Color? color;
}

/// The app's one tab / segmented control: a soft grey track with a raised,
/// glossy white pill under the selected option, which slides between options.
///
/// Used for switches (Residential / Commercial), form choices (building type,
/// priority) and anywhere else one of a few options is picked.
class AppSegmentedTabs<T> extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.height = 44,
  });

  final List<AppTabItem<T>> items;
  final T value;

  /// Null disables the control (e.g. a locked choice).
  final ValueChanged<T>? onChanged;
  final double height;

  static const _duration = Duration(milliseconds: 220);
  static const _inset = 4.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final index = items.indexWhere((i) => i.value == value);
    final enabled = onChanged != null;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(_inset),
        decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segment = constraints.maxWidth / items.length;
            return Stack(
              children: [
                if (index >= 0)
                  AnimatedPositioned(
                    duration: _duration,
                    curve: Curves.easeOutCubic,
                    left: segment * index,
                    top: 0,
                    bottom: 0,
                    width: segment,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md - _inset / 2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [palette.card, palette.cardSheenEnd],
                        ),
                        border: Border.all(color: palette.cardEdge, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _Segment(
                          item: items[i],
                          selected: i == index,
                          selectedColor: items[i].color ?? scheme.primary,
                          idleColor: scheme.onSurfaceVariant,
                          onTap: enabled && i != index ? () => onChanged!(items[i].value) : null,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.item,
    required this.selected,
    required this.selectedColor,
    required this.idleColor,
    required this.onTap,
  });

  final AppTabItem<T> item;
  final bool selected;
  final Color selectedColor;
  final Color idleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : idleColor;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: AppSegmentedTabs._duration,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 16, color: color),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
