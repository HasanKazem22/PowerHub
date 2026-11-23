import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../indicators/app_page_dots.dart';
import 'app_promo_banner.dart';

/// One card of an [AppTipsCarousel].
class AppTip {
  const AppTip({
    required this.id,
    required this.icon,
    required this.badge,
    required this.title,
    required this.detail,
    required this.onTap,
    this.actionLabel = 'Try it',
  });

  /// Stable id, used to remember the tip was closed.
  final String id;
  final IconData icon;
  final String badge;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onTap;
}

/// Swipeable [AppPromoBanner]s with page dots under them. Each tip opens its feature on tap and can be closed with
/// × ([onDismiss]); shows nothing once [tips] is empty.
class AppTipsCarousel extends StatefulWidget {
  const AppTipsCarousel({super.key, required this.tips, required this.onDismiss});

  final List<AppTip> tips;
  final ValueChanged<AppTip> onDismiss;

  @override
  State<AppTipsCarousel> createState() => _AppTipsCarouselState();
}

class _AppTipsCarouselState extends State<AppTipsCarousel> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tips = widget.tips;
    if (tips.isEmpty) return const SizedBox.shrink();
    final index = _index.clamp(0, tips.length - 1);
    // The banner caps text scaling at 1.25; leave room for the bigger text.
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.25);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 148 * scale, // fits a two-line title and a two-line detail on a narrow phone
          child: PageView.builder(
            controller: _pages,
            itemCount: tips.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final tip = tips[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AppPromoBanner(
                  icon: tip.icon,
                  badge: tip.badge,
                  title: tip.title,
                  detail: tip.detail,
                  actionLabel: tip.actionLabel,
                  onTap: tip.onTap,
                  closeTooltip: 'Hide this tip',
                  onClose: () => widget.onDismiss(tip),
                ),
              );
            },
          ),
        ),
        if (tips.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          AppPageDots(
            count: tips.length,
            index: index,
            onTap: (i) =>
                _pages.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
          ),
        ],
      ],
    );
  }
}
