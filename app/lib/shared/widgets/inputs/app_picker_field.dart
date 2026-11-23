import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// A tappable value that looks exactly like a text field (same fill, radius,
/// height and floating label), for values picked from a dialog or sheet
/// rather than typed: dates, months, and so on.
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.trailingIcon = Icons.expand_more_rounded,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final IconData? icon;
  final IconData trailingIcon;

  /// When set, a clear (×) button replaces [trailingIcon] (optional values).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon, size: 20),
          suffixIcon: onClear == null
              ? Icon(trailingIcon)
              : IconButton(icon: const Icon(Icons.close_rounded), tooltip: 'Clear', onPressed: onClear),
        ),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
