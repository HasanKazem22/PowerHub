import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class PowerHubApp extends StatelessWidget {
  const PowerHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      // Always the off-white light look, even when the phone is in dark mode
      // (same as the other Bear Tech apps). AppTheme.dark() is kept for later.
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
