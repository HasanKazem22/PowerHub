import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/backup/presentation/backup_screen.dart';
import '../../features/calc/presentation/calc_screen.dart';
import '../../features/guide/presentation/guide_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(path: AppRoutes.welcome, builder: (_, _) => const OnboardingScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: AppRoutes.history, builder: (_, _) => const HistoryScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: AppRoutes.guide, builder: (_, _) => const GuideScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen())],
        ),
      ],
    ),
    // Pages opened on top of the tabs.
    GoRoute(path: AppRoutes.backup, parentNavigatorKey: _rootKey, builder: (_, _) => const BackupScreen()),
    GoRoute(
      path: AppRoutes.calcPath,
      parentNavigatorKey: _rootKey,
      builder: (_, state) => CalcScreen(
        // A new key per project, so opening another project builds a fresh screen.
        key: ValueKey(state.uri.toString()),
        moduleId: state.pathParameters['module']!,
        projectId: state.uri.queryParameters['project'],
      ),
    ),
  ],
);
