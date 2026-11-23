import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'app_avatar.dart';

/// "Good evening, Hasibul Hasan" with the initials avatar, at the top of Home.
class AppGreeting extends StatelessWidget {
  const AppGreeting({super.key, required this.name, this.placeholder = 'Tap to add your name', this.onTap, this.now});

  /// Empty when the user hasn't set a name yet.
  final String name;
  final String placeholder;
  final VoidCallback? onTap;

  /// Injectable for tests.
  final DateTime? now;

  static String greetingFor(DateTime time) {
    final hour = time.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Names typed in capitals ("HASIBUL HASAN") read as shouting; show title case.
  static String displayName(String raw) => raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w.length == 1 ? w.toUpperCase() : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final shown = displayName(name);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            AppAvatar(name: shown),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greetingFor(now ?? DateTime.now()),
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    shown.isEmpty ? placeholder : shown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: shown.isEmpty
                        ? text.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)
                        : text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
