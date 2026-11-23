import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gloss.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../misc/app_glass.dart';
import 'app_nav_glyph.dart';

/// One destination of [AppBottomNav].
class AppNavItem {
  const AppNavItem(this.kind, this.label, {this.selectable = true});
  final AppNavGlyphKind kind;
  final String label;

  /// False for an action item (Add) that opens something instead of a tab.
  final bool selectable;
}

/// The app's five bottom destinations, on frosted glass (same design as the
/// other Bear Tech apps).
///
/// The page scrolls underneath the bar and shows through it blurred. For that
/// the hosting Scaffold sets `extendBody: true`, and scroll views end with
/// [bottomInset] so their last item can scroll clear of the bar.
///
/// The active tab is marked by a filled icon and a coloured label rather than
/// a pill behind it; on glass, a solid shape would break the effect.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Height of the bar's content, above the system navigation inset.
  static const double barHeight = 66;

  /// How far the round action button (Add) rises above the bar.
  static const double actionRaise = 12;

  /// Diameter of the round action button.
  static const double actionSize = 58;

  /// Space to leave at the end of a scroll view so its last item clears the
  /// bar. With `extendBody: true` the Scaffold reports the bar's height as the
  /// bottom padding; elsewhere this is just the system inset.
  static double bottomInset(BuildContext context) => MediaQuery.paddingOf(context).bottom;

  static const _inactiveLight = AppColors.navInactive;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final scheme = Theme.of(context).colorScheme;
    final inactive = dark ? scheme.onSurfaceVariant : _inactiveLight;
    final actionIndex = items.indexWhere((i) => !i.selectable);

    final bar = AppGlass(
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: i == actionIndex
                      ? _ActionSlot(onTap: () => onTap(i))
                      : _NavItem(
                          item: items[i],
                          selected: i == currentIndex,
                          active: scheme.primary,
                          inactive: inactive,
                          onTap: () => onTap(i),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
    if (actionIndex < 0) return bar;

    // The round button sits in the extra space above the glass, overlapping
    // its top edge. Taps beside it fall through to the page underneath.
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: actionRaise),
          child: bar,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: i == actionIndex
                      ? Center(
                          child: _ActionButton(label: items[i].label, onTap: () => onTap(i)),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The raised round Add button: glossy brand-green disc in a white ring, with
/// a soft green glow, standing above the bar.
class _ActionButton extends StatefulWidget {
  const _ActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const size = AppBottomNav.actionSize;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.palette.card,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.30),
                  blurRadius: 14,
                  spreadRadius: -4,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGloss.brandButton),
              child: DecoratedBox(
                // Gloss across the top half.
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGloss.sheen(strength: 0.22)),
                child: const Icon(Icons.add_rounded, color: AppColors.onBrand, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bar space under the raised button: no label, just a larger tap area.
class _ActionSlot extends StatelessWidget {
  const _ActionSlot({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap);
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.active,
    required this.inactive,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final Color active;
  final Color inactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? active : inactive;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        highlightColor: Colors.transparent,
        splashColor: active.withValues(alpha: 0.10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: AppNavGlyph(key: ValueKey(selected), kind: item.kind, filled: selected, color: color, size: 31),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2),
              style: TextStyle(
                fontSize: 12.5,
                height: 1.2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
