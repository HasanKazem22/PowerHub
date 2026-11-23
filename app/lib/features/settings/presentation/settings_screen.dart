import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/backup/drive_backup_service.dart';
import '../../../data/providers.dart';
import '../../../shared/layouts/app_page.dart';
import '../../../shared/widgets/branding/bear_tech_logo.dart';
import '../../../shared/widgets/indicators/app_icon_badge.dart';
import '../../../shared/widgets/lists/app_list_card.dart';
import '../../../shared/widgets/lists/app_list_tile.dart';
import '../../../shared/widgets/misc/app_avatar.dart';
import '../../../shared/widgets/misc/app_greeting.dart';
import '../../../shared/widgets/misc/section_header.dart';
import 'widgets/engineer_credit.dart';
import 'widgets/name_sheet.dart';

/// Profile (name and company for reports), backup, and about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = AppGreeting.displayName(ref.watch(userNameProvider).value ?? '');
    final company = ref.watch(companyProvider).value ?? '';
    final saved = ref.watch(projectsProvider).value?.length ?? 0;
    final backupAvailable = ref.watch(driveBackupServiceProvider) != null;
    final backup = ref.watch(driveBackupStatusProvider).value;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final chevron = Icon(Icons.chevron_right_rounded, color: muted);
    Widget badge(IconData icon, Color color) => AppIconBadge(icon: icon, color: color, size: AppSpacing.listIcon);

    return AppPage(
      title: 'Settings',
      children: [
        const SectionHeader('Profile'),
        AppListCard(
          children: [
            AppListTile(
              leading: AppAvatar(name: name, size: AppSpacing.listIcon),
              title: name.isEmpty ? 'Add your name' : name,
              subtitle: company.isEmpty ? 'Shown on Home and on reports' : company,
              trailing: chevron,
              onTap: () => showNameSheet(context),
            ),
            AppListTile(
              leading: badge(
                backup?.on ?? false ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                backup?.problem != null ? AppColors.warning : AppColors.tileGreen,
              ),
              title: 'Backup & restore',
              subtitle: _backupSummary(backupAvailable, backup, saved),
              subtitleMaxLines: 2,
              trailing: chevron,
              onTap: () => AppActions.open(context, AppRoutes.backup),
            ),
          ],
        ),
        const SectionHeader('About'),
        AppListCard(
          children: [
            AppListTile(
              leading: badge(Icons.rule_rounded, AppColors.tileBlue),
              title: 'Codes followed',
              subtitle:
                  'BNBC 2020 Part 8 and IEC (60364, 60076, 62271, 60947, 62548, …). Each calculator lists its basis '
                  'at the end. Confirm final designs with the utility (DPDC, DESCO, BPDB, PBS).',
              subtitleMaxLines: 5,
            ),
            AppListTile(
              leading: badge(Icons.verified_user_outlined, AppColors.tileTeal),
              title: 'Private by design',
              subtitle:
                  'No account and no ${AppConstants.appName} servers. Your projects stay on this phone, and in '
                  'your own Google Drive if you turn on backup.',
              subtitleMaxLines: 4,
            ),
          ],
        ),
        const SectionHeader('Engineer'),
        const AppListCard(children: [EngineerTile()]),
        const SizedBox(height: AppSpacing.xxxl),
        const Center(child: BearTechCredit(caption: '${AppConstants.appName} · Version ${AppConstants.appVersion}')),
      ],
    );
  }

  static String _backupSummary(bool available, DriveBackupStatus? backup, int saved) {
    final projects = '$saved project${saved == 1 ? '' : 's'}';
    if (!available || backup == null || !backup.on) return 'Off. $projects only on this phone';
    if (backup.problem != null) return 'Paused. Tap to fix';
    final last = backup.lastBackupAt;
    return last == null
        ? 'Google Drive · ${backup.account}'
        : 'Google Drive · Last backup ${DateFormat('d MMM, h:mm a').format(last)}';
  }
}
