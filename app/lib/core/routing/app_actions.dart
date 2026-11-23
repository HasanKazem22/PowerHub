import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/database.dart';
import '../../features/calc/modules/modules.dart';
import '../../shared/widgets/dialogs/app_action_sheet.dart';
import 'app_routes.dart';

/// Things the user can start from several places (the "+" button, Home's
/// calculator grid, History, empty states). One function each, so they all
/// behave the same.
abstract final class AppActions {
  /// Opens a calculator with its work in progress (or its typical values).
  static void openCalc(BuildContext context, String moduleId) => context.push(AppRoutes.calc(moduleId));

  /// Opens a saved project in its calculator.
  static void openProject(BuildContext context, Project project) =>
      context.push(AppRoutes.calc(project.module, projectId: project.id));

  /// The "+" menu: every calculator.
  static Future<void> showNewMenu(BuildContext context) => showAppActionSheet(
    context,
    title: 'New calculation',
    actions: [
      for (final m in calcModules)
        AppSheetAction(
          icon: m.icon,
          label: m.title,
          subtitle: m.subtitle,
          color: m.color,
          onTap: () => openCalc(context, m.id),
        ),
    ],
  );

  /// Switches to a bottom-bar tab.
  static void goTo(BuildContext context, String route) => context.go(route);

  /// Opens a page on top (Backup & restore).
  static void open(BuildContext context, String route) => context.push(route);
}
