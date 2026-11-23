import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_error.dart';
import '../../../data/backup/drive_backup_service.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../shared/layouts/app_page.dart';
import '../../../shared/widgets/branding/app_logo.dart';
import '../../../shared/widgets/branding/bear_tech_logo.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/cards/app_info_banner.dart';
import '../../../shared/widgets/cards/app_summary_card.dart';
import '../../../shared/widgets/cards/app_tips_carousel.dart';
import '../../../shared/widgets/grids/app_icon_grid.dart';
import '../../../shared/widgets/grids/app_icon_tile.dart';
import '../../../shared/widgets/lists/app_list_card.dart';
import '../../../shared/widgets/misc/app_greeting.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/section_header.dart';
import '../../calc/modules/modules.dart';
import '../../history/presentation/widgets/project_tile.dart';
import '../../settings/presentation/widgets/name_sheet.dart';

final _tipsDismissedProvider = StreamProvider<Set<String>>(
  (ref) => ref
      .watch(databaseProvider)
      .watchSetting(SettingKeys.tipsDismissed)
      .map((v) => {...?v?.split(',').where((s) => s.isNotEmpty)}),
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userNameProvider).value ?? '';
    final projectsAsync = ref.watch(projectsProvider);
    final projects = projectsAsync.value ?? const <Project>[];
    // Google backup: a problem to fix, or a reminder to turn it on once there is work worth keeping.
    final backupAvailable = ref.watch(driveBackupServiceProvider) != null;
    final backup = backupAvailable ? ref.watch(driveBackupStatusProvider).value : null;
    final dismissed = ref.watch(_tipsDismissedProvider).value ?? const <String>{};

    final now = DateTime.now();
    final thisMonth = projects.where((p) => p.updatedAt.year == now.year && p.updatedAt.month == now.month).length;
    final last = projects.firstOrNull;

    final tips = [
      AppTip(
        id: 'save',
        icon: Icons.bookmark_add_outlined,
        badge: 'How it works',
        title: 'Save each design as a project',
        detail: 'Tap Save on any calculator and name it. Open it again from History any time.',
        actionLabel: 'Start',
        onTap: () => AppActions.showNewMenu(context),
      ),
      if (backupAvailable)
        AppTip(
          id: 'drive',
          icon: Icons.add_to_drive_rounded,
          badge: 'Free',
          title: 'Keep projects in Google Drive',
          detail: 'Encrypted backup to your own Drive. Restore on a new phone in a minute.',
          actionLabel: 'Turn on',
          onTap: () => AppActions.open(context, AppRoutes.backup),
        ),
      AppTip(
        id: 'report',
        icon: Icons.picture_as_pdf_outlined,
        badge: 'Reports',
        title: 'Share a PDF report',
        detail: 'Full working for the designer, or a clean summary for the customer.',
        actionLabel: 'History',
        onTap: () => AppActions.goTo(context, AppRoutes.history),
      ),
    ].where((t) => !dismissed.contains(t.id)).toList();

    return AppPage(
      titleWidget: const AppLogoTitle(),
      children: [
        AppGreeting(name: name, onTap: () => showNameSheet(context)),
        const SizedBox(height: AppSpacing.xl),
        if (projectsAsync.hasError) ...[
          AppInfoBanner(
            type: AppBannerType.error,
            message: '${databaseErrorMessage(projectsAsync.error!)}\nTap to copy the details.',
            onTap: () {
              Clipboard.setData(ClipboardData(text: describeError(projectsAsync.error!, maxLength: 4000)));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error copied')));
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else if (backup?.problem != null) ...[
          AppInfoBanner(
            type: AppBannerType.warning,
            icon: Icons.cloud_off_outlined,
            message: 'Your Google backup is paused. Tap to fix it.',
            onTap: () => AppActions.open(context, AppRoutes.backup),
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else if (backup != null && !backup.on && projects.length >= 3) ...[
          AppInfoBanner(
            icon: Icons.add_to_drive_rounded,
            message: 'Your ${projects.length} projects are only on this phone. Turn on free Google backup.',
            onTap: () => AppActions.open(context, AppRoutes.backup),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppSummaryCard(
          label: 'Saved projects',
          value: '${projects.length}',
          caption: last == null ? 'Pick a calculator below to start' : 'Last: ${last.name} · ${projectDate(last.updatedAt)}',
          actionLabel: 'New',
          onAction: () => AppActions.showNewMenu(context),
          metrics: [
            AppSummaryMetric('This month', '$thisMonth', icon: Icons.calendar_today_outlined, accent: AppColors.goldLight),
            AppSummaryMetric('Calculators', '${calcModules.length}', icon: Icons.calculate_outlined),
            AppSummaryMetric(
              'Backup',
              backup?.on ?? false ? 'On' : 'Off',
              icon: backup?.on ?? false ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            ),
          ],
        ),
        const SectionHeader('Calculators'),
        AppIconGrid(
          tiles: [
            for (final m in calcModules)
              AppIconTileData(
                icon: m.icon,
                label: m.shortTitle,
                color: m.color,
                onTap: () => AppActions.openCalc(context, m.id),
              ),
            AppIconTileData(
              icon: Icons.health_and_safety_outlined,
              label: 'Fault\nguide',
              color: AppColors.tileRed,
              onTap: () => AppActions.goTo(context, AppRoutes.guide),
            ),
          ],
        ),
        if (tips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          AppTipsCarousel(
            tips: tips,
            onDismiss: (tip) => ref
                .read(databaseProvider)
                .setSetting(SettingKeys.tipsDismissed, {...dismissed, tip.id}.join(',')),
          ),
        ],
        SectionHeader(
          'Recent projects',
          actionLabel: projects.isEmpty ? null : 'See all',
          onAction: () => AppActions.goTo(context, AppRoutes.history),
        ),
        if (projects.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'No saved projects yet',
              message: 'Your saved calculations show up here.',
              actionLabel: 'New calculation',
              actionIcon: Icons.add_rounded,
              onAction: () => AppActions.showNewMenu(context),
            ),
          )
        else
          AppListCard(children: [for (final p in projects.take(4)) ProjectTile(project: p)]),
        const SizedBox(height: AppSpacing.xxxl),
        const Center(child: BearTechCredit(caption: '${AppConstants.appName} · Version ${AppConstants.appVersion}')),
      ],
    );
  }
}
