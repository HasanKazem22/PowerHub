import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';

/// Round tick in the same size as a list icon disc: an empty glossy disc when
/// unchecked, a filled brand-green disc with a tick when checked.
class AppCheckBadge extends StatelessWidget {
  const AppCheckBadge({
    super.key,
    required this.checked,
    required this.onChanged,
    this.size = AppSpacing.listIcon,
    this.tooltip,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    return Semantics(
      checked: checked,
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkResponse(
          onTap: () => onChanged(!checked),
          radius: size * 0.6,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? scheme.primary : null,
              gradient: checked
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [palette.iconCircleSheen, palette.iconCircle],
                    ),
              border: Border.all(color: checked ? scheme.primary : scheme.outlineVariant, width: checked ? 0 : 1.4),
            ),
            child: Icon(
              Icons.check_rounded,
              size: size * 0.5,
              color: checked ? scheme.onPrimary : scheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}
