import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Round avatar with the person's initials on a brand-green gradient.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.size = 46});
  final String name;
  final double size;

  /// "Hasibul Hasan" → "HH", "Hasibul" → "H", "Abbu & Ammu (wedding)" → "AA": only words count (not "&" or a
  /// note in brackets).
  static String initials(String name) {
    final plain = name.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    final words = [for (final m in RegExp(r'[\p{L}\p{N}]+', unicode: true).allMatches(plain)) m.group(0)!];
    if (words.isEmpty) return '';
    final first = words.first.characters.first;
    final last = words.length > 1 ? words.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final text = initials(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.primary],
        ),
      ),
      child: text.isEmpty
          ? Icon(Icons.person_rounded, color: AppColors.onBrand, size: size * 0.5)
          : Text(
              text,
              style: TextStyle(color: AppColors.onBrand, fontSize: size * 0.35, fontWeight: FontWeight.w700),
            ),
    );
  }
}
