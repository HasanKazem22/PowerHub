import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/backup/presentation/auto_backup.dart';
import '../../shared/widgets/navigation/app_bottom_nav.dart';
import '../../shared/widgets/navigation/app_nav_glyph.dart';
import 'app_actions.dart';

/// Tab pages with the frosted bottom bar:
/// Home · History · New (opens the calculator menu) · Guide · Settings
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  /// Bar items. Index 2 (New) opens the calculator menu; the others are the four tabs.
  static const _items = [
    AppNavItem(AppNavGlyphKind.home, 'Home'),
    AppNavItem(AppNavGlyphKind.history, 'History'),
    AppNavItem(AppNavGlyphKind.add, 'New', selectable: false),
    AppNavItem(AppNavGlyphKind.guide, 'Guide'),
    AppNavItem(AppNavGlyphKind.settings, 'Settings'),
  ];
  static const _addIndex = 2;

  @override
  Widget build(BuildContext context) {
    final branch = shell.currentIndex;
    // Backs up to Google Drive by itself when a backup is due.
    return AutoBackup(
      child: Scaffold(
        // The page runs underneath the frosted bar and shows through it.
        extendBody: true,
        body: shell,
        bottomNavigationBar: AppBottomNav(
          items: _items,
          currentIndex: branch >= _addIndex ? branch + 1 : branch,
          onTap: (i) {
            if (i == _addIndex) {
              AppActions.showNewMenu(context);
              return;
            }
            final target = i > _addIndex ? i - 1 : i;
            shell.goBranch(target, initialLocation: target == branch);
          },
        ),
      ),
    );
  }
}
