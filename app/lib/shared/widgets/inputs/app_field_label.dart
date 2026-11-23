import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Small label above a group of inputs that has no floating label of its own
/// (category chips, tabs): "Category", "Priority".
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
