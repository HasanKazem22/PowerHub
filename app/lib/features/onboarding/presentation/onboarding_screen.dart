import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/backup/drive_backup_service.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/branding/app_logo.dart';
import '../../../shared/widgets/branding/bear_tech_logo.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/indicators/app_page_dots.dart';
import '../../backup/presentation/google_backup_flow.dart';
import 'widgets/onboarding_illustration.dart';

class _Slide {
  const _Slide(this.title, this.message, this.icon, this.satellites);
  final String title;
  final String message;
  final IconData icon;
  final List<OnboardingSatellite> satellites;
}

const _slides = [
  _Slide(
    'Size it right, in minutes',
    'Building load, substation, power factor, solar, motor feeder, rewinding and earthing. As you type, the answer updates.',
    Icons.bolt_rounded,
    [
      OnboardingSatellite(Icons.apartment_outlined, AppColors.tileBlue, Alignment(-0.92, -0.38)),
      OnboardingSatellite(Icons.electrical_services_outlined, AppColors.tileTeal, Alignment(0.9, -0.2)),
      OnboardingSatellite(Icons.solar_power_outlined, AppColors.tileAmber, Alignment(0.18, 0.95)),
    ],
  ),
  _Slide(
    'BNBC and IEC, with the working',
    'Standard breaker, cable, CT and transformer sizes, warnings with one-tap fixes, and the step-by-step calculation.',
    Icons.rule_rounded,
    [
      OnboardingSatellite(Icons.warning_amber_rounded, AppColors.warning, Alignment(-0.9, -0.3)),
      OnboardingSatellite(Icons.functions_rounded, AppColors.tilePurple, Alignment(0.92, -0.35)),
      OnboardingSatellite(Icons.auto_fix_high_rounded, AppColors.tileGreen, Alignment(-0.1, 0.96)),
    ],
  ),
  _Slide(
    'Save every design as a project',
    'Name it, find it in History, change it later, and share a PDF report with the designer or the customer.',
    Icons.folder_rounded,
    [
      OnboardingSatellite(Icons.bookmark_added_outlined, AppColors.tileBlue, Alignment(-0.92, -0.25)),
      OnboardingSatellite(Icons.picture_as_pdf_outlined, AppColors.tileRed, Alignment(0.9, -0.4)),
      OnboardingSatellite(Icons.history_rounded, AppColors.tileOrange, Alignment(0.22, 0.96)),
    ],
  ),
  _Slide(
    'Private, and works offline',
    'No account needed. Your projects stay on your phone, with free, encrypted Google Drive backup if you want it.',
    Icons.lock_rounded,
    [
      OnboardingSatellite(Icons.wifi_off_rounded, AppColors.tileSlate, Alignment(-0.9, -0.35)),
      OnboardingSatellite(Icons.verified_user_outlined, AppColors.tileGreen, Alignment(0.92, -0.25)),
      OnboardingSatellite(Icons.add_to_drive_rounded, AppColors.tileBlue, Alignment(-0.15, 0.96)),
    ],
  ),
];

/// Shown once after install: what PowerHub can do, in four slides, then Home.
/// "Skip" and "Get started" both mark the slides as seen. On the last slide,
/// someone moving to a new phone can restore their Google Drive backup instead.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) =>
      _pages.animateToPage(page, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);

  Future<void> _finish() async {
    try {
      await ref.read(databaseProvider).setSetting(SettingKeys.onboardingDone, '1');
    } catch (_) {
      // Not remembered: the slides show again next time. Never block the user.
    }
    if (mounted) context.go(AppRoutes.home);
  }

  Future<void> _restore() async {
    if (await GoogleBackupFlow.restore(context, ref)) await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final canRestore = ref.watch(driveBackupServiceProvider) != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Wordmark and Skip.
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.sm, 0),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const AppLogo(height: 22),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _isLast ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: TextButton(onPressed: _isLast ? null : _finish, child: const Text('Skip')),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.lg),
              child: Column(
                children: [
                  AppPageDots(count: _slides.length, index: _index, onTap: _goTo),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: _isLast ? 'Get started' : 'Next',
                    onPressed: _isLast ? _finish : () => _goTo(_index + 1),
                  ),
                  if (canRestore)
                    // Kept in the layout on every slide so the buttons never jump.
                    Visibility(
                      visible: _isLast,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: TextButton.icon(
                        onPressed: _isLast ? _restore : null,
                        icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                        label: const Text('Restore from Google Drive'),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.md),
                  const BearTechCredit(logoHeight: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Artwork scales with the space left for it, so short phones fit.
        final art = (constraints.maxHeight * 0.55).clamp(160.0, 300.0).clamp(0.0, constraints.maxWidth * 0.8);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OnboardingIllustration(icon: slide.icon, satellites: slide.satellites, size: art),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  slide.message,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: muted, height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
