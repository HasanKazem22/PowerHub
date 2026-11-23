import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_error.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/branding/app_logo.dart';
import '../../../shared/widgets/branding/bear_tech_logo.dart';

/// Off-white splash with the logo in a raised off-white circle, the name and tagline,
/// a loader and the version. Opens the database meanwhile, then goes to Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final minimumTime = Future<void>.delayed(const Duration(milliseconds: 1400));
    // Listen while waiting: Riverpod pauses a provider nobody listens to, and a
    // bare `ref.read(...future)` is not a listener, so the first result could
    // never arrive (seen in the browser, where the database answers slower).
    // Closed automatically when the splash is disposed.
    ref.listenManual(projectsProvider, (_, _) {});
    try {
      // Opens the database (creating it on first launch). Never hang on the
      // splash: after the timeout Home takes over with its own states.
      await ref.read(projectsProvider.future).timeout(const Duration(seconds: 10));
    } catch (e, st) {
      // Home shows the error in a banner; also log it (visible in logcat).
      debugPrint('PowerHub: database failed to open: ${describeError(e, maxLength: 4000)}');
      debugPrintStack(stackTrace: st);
    }
    final firstLaunch = await _isFirstLaunch();
    await minimumTime;
    if (mounted) context.go(firstLaunch ? AppRoutes.welcome : AppRoutes.home);
  }

  /// True until the welcome slides have been seen. If the setting can't be
  /// read, go straight to Home rather than block the app.
  Future<bool> _isFirstLaunch() async {
    try {
      final done = await ref.read(databaseProvider).getSetting(SettingKeys.onboardingDone);
      return done == null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final logoHeight = (width * 0.13).clamp(40.0, 64.0);
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    // Same warm off-white page as the welcome slides and the rest of the app
    // (the native launch screen uses this colour too, so there is no flash).
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const Spacer(flex: 2),
            AppLogo(height: logoHeight),
            const SizedBox(height: AppSpacing.md),
            Text(AppConstants.tagline, style: text.bodyMedium?.copyWith(color: muted)),
            const Spacer(flex: 3),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(color: AppColors.brand, strokeWidth: 3),
                  ),
                  const SizedBox(height: 18),
                  Text('LOADING', style: text.labelSmall?.copyWith(color: muted, letterSpacing: 2)),
                  const SizedBox(height: AppSpacing.xxl),
                  const BearTechCredit(caption: 'Version ${AppConstants.appVersion}'),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
