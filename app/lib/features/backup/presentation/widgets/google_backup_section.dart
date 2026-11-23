import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/backup/backup_exceptions.dart';
import '../../../../data/backup/drive_backup_service.dart';
import '../../../../shared/widgets/buttons/app_google_button.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../../../../shared/widgets/cards/app_info_banner.dart';
import '../../../../shared/widgets/dialogs/app_action_sheet.dart';
import '../../../../shared/widgets/dialogs/app_confirm_dialog.dart';
import '../../../../shared/widgets/dialogs/app_progress_dialog.dart';
import '../../../../shared/widgets/indicators/app_icon_badge.dart';
import '../../../../shared/widgets/lists/app_list_card.dart';
import '../../../../shared/widgets/lists/app_list_tile.dart';
import '../google_backup_flow.dart';
import 'backup_password_sheets.dart';

/// Google Drive backup on the Backup & restore screen: "Back up with Google" when off; when on, the last backup,
/// automatic backup, the backup password, the account, and restore.
class GoogleBackupSection extends ConsumerStatefulWidget {
  const GoogleBackupSection({super.key});

  @override
  ConsumerState<GoogleBackupSection> createState() => _GoogleBackupSectionState();
}

class _GoogleBackupSectionState extends ConsumerState<GoogleBackupSection> {
  bool _busy = false;

  DriveBackupService get _service => ref.read(driveBackupServiceProvider)!;

  // ── Actions ────────────────────────────────────────────

  Future<void> _turnOn() => _locked(() => GoogleBackupFlow.turnOn(context, ref));

  Future<void> _restore() => _locked(() => GoogleBackupFlow.restore(context, ref));

  Future<void> _backupNow() => _locked(() async {
    if (await _try(() => runWithProgress(context, 'Backing up to Google Drive…', _service.backupNow))) {
      _snack('Backed up to Google Drive.');
    }
  });

  Future<void> _setAutomatic(bool on) => _service.setAutomatic(on);

  Future<void> _passwordMenu(bool protected) async {
    if (!protected) {
      final answer = await showSetBackupPasswordSheet(context, changing: false);
      if (answer == null || !mounted) return;
      final ok = await _locked(
        () => _try(() => runWithProgress(context, 'Locking your backup…', () => _service.setPassword(answer.password))),
      );
      if (ok ?? false) _snack('Backup password set. You will need it to restore on a new phone.');
      return;
    }
    showAppActionSheet(
      context,
      title: 'Backup password',
      actions: [
        AppSheetAction(icon: Icons.password_rounded, label: 'Change password', onTap: _changePassword),
        AppSheetAction(
          icon: Icons.lock_open_rounded,
          label: 'Remove password',
          subtitle: 'Your backup stays private to your Google account',
          onTap: _removePassword,
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    final answer = await showSetBackupPasswordSheet(context, changing: true);
    if (answer == null || !mounted) return;
    final ok = await _locked(
      () => _try(
        () => runWithProgress(
          context,
          'Changing your password…',
          () => _service.setPassword(answer.password, current: answer.current),
        ),
      ),
    );
    if (ok ?? false) _snack('Backup password changed.');
  }

  Future<void> _removePassword() async {
    final answer = await askBackupPassword(
      context,
      title: 'Remove backup password',
      subtitle: 'Enter your current password to remove it.',
      confirmLabel: 'Remove password',
    );
    final password = answer?.password;
    if (password == null || !mounted) return;
    final ok = await _locked(
      () => _try(() => runWithProgress(context, 'Removing the password…', () => _service.removePassword(password))),
    );
    if (ok ?? false) _snack('Backup password removed.');
  }

  /// Everything except "Back up now", in one menu so the screen stays simple.
  void _settingsMenu(DriveBackupStatus status) {
    showAppActionSheet(
      context,
      title: 'Backup settings',
      actions: [
        AppSheetAction(
          icon: Icons.autorenew_rounded,
          label: 'Automatic backup: ${status.automatic ? 'On' : 'Off'}',
          subtitle: status.automatic ? 'Tap to turn off' : 'Tap to turn on',
          onTap: () => _setAutomatic(!status.automatic),
        ),
        AppSheetAction(
          icon: status.passwordProtected ? Icons.lock_rounded : Icons.lock_open_rounded,
          label: 'Backup password: ${status.passwordProtected ? 'On' : 'Off'}',
          subtitle: status.passwordProtected ? 'Change or remove it' : 'Only you can open your backup',
          onTap: () => _passwordMenu(status.passwordProtected),
        ),
        AppSheetAction(
          icon: Icons.settings_backup_restore_rounded,
          label: 'Restore from Google Drive',
          subtitle: 'Replaces the data on this phone',
          onTap: _restore,
        ),
        AppSheetAction(
          icon: Icons.cloud_off_outlined,
          label: 'Turn off backup',
          subtitle: 'Your backup stays in Google Drive',
          onTap: () => _turnOff(delete: false),
        ),
        AppSheetAction(
          icon: Icons.delete_outline_rounded,
          label: 'Delete backup',
          subtitle: 'Removes it from Google Drive',
          color: AppColors.error,
          onTap: () => _turnOff(delete: true),
        ),
      ],
    );
  }

  Future<void> _turnOff({required bool delete}) async {
    final ok = await showAppConfirmDialog(
      context,
      title: delete ? 'Delete your backup?' : 'Turn off backup?',
      message: delete
          ? 'Your PowerHub backup is deleted from Google Drive and cannot be brought back. '
                'Your data on this phone stays.'
          : 'PowerHub stops backing up. Your data on this phone and your last backup in Google Drive stay.',
      confirmLabel: delete ? 'Delete backup' : 'Turn off',
      destructive: delete,
    );
    if (!ok || !mounted) return;
    final done = await _locked(
      () => _try(() => runWithProgress(context, 'Turning off backup…', () => _service.turnOff(deleteBackups: delete))),
    );
    if (done ?? false) _snack(delete ? 'Backup deleted from Google Drive.' : 'Backup is off.');
  }

  /// The banner's fix for a problem automatic backup ran into.
  Future<void> _fix(BackupErrorCode problem) async {
    if (problem != BackupErrorCode.replacedElsewhere) return _backupNow();
    showAppActionSheet(
      context,
      title: 'Your backup changed',
      actions: [
        AppSheetAction(
          icon: Icons.settings_backup_restore_rounded,
          label: 'Restore it on this phone',
          subtitle: 'Replaces the data on this phone with the backup',
          onTap: _restore,
        ),
        AppSheetAction(
          icon: Icons.cloud_upload_outlined,
          label: "Replace it with this phone's data",
          subtitle: 'The backup in Google Drive is overwritten',
          onTap: () => _locked(() => GoogleBackupFlow.replaceWithThisPhone(context, ref)),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────

  /// One action at a time; null when another is running.
  Future<T?> _locked<T>(Future<T> Function() action) async {
    if (_busy) return null;
    setState(() => _busy = true);
    try {
      return await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Runs [action]; shows its error and returns false on failure.
  Future<bool> _try(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on BackupException catch (e) {
      if (e.code != BackupErrorCode.canceled) _snack(e.message);
    } catch (e) {
      debugPrint('PowerHub: Google backup action failed: $e');
      _snack('Something went wrong. Please try again.');
    }
    return false;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── UI ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (ref.watch(driveBackupServiceProvider) == null) {
      // Off in the browser (a design preview only) or in a build without the Google client ID (see AppConfig).
      return AppInfoBanner(
        icon: Icons.cloud_queue_rounded,
        message: switch ((kIsWeb, kReleaseMode)) {
          (true, true) =>
            'Google Drive backup works in the PowerHub phone app (Android and iPhone). '
                'In the browser, save a backup file below.',
          (false, true) => 'Google Drive backup is coming soon. Until then, save a backup file below.',
          (_, false) =>
            'Developer setup needed: Google backup needs GOOGLE_SERVER_CLIENT_ID. Run with '
                '--dart-define-from-file=config/dev.json (the PowerHub run configuration does this).',
        },
      );
    }
    final status = ref.watch(driveBackupStatusProvider).value;
    if (status == null) return const SizedBox.shrink();
    return status.on ? _onView(status) : _offView();
  }

  Widget _offView() {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Save your data in your Google Drive. Get it back on any phone.',
                style: text.bodyMedium?.copyWith(color: muted, height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              AppGoogleButton(label: 'Back up with Google', busy: _busy, onPressed: _turnOn),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppListCard(
          children: [
            _tile(
              Icons.settings_backup_restore_rounded,
              AppColors.tileBlue,
              'Restore from Google Drive',
              'From a backup made on another phone.',
              _restore,
            ),
          ],
        ),
      ],
    );
  }

  Widget _onView(DriveBackupStatus status) {
    final last = status.lastBackupAt;
    final problem = status.problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (problem != null) ...[
          AppInfoBanner(
            type: AppBannerType.warning,
            icon: Icons.cloud_off_outlined,
            message: _problemMessage(problem),
            onTap: _busy ? null : () => _fix(problem),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppListCard(
          children: [
            _tile(
              Icons.cloud_upload_outlined,
              AppColors.tileGreen,
              'Back up now',
              last == null ? status.account! : 'Last backup: ${DateFormat('d MMM, h:mm a').format(last)}',
              _backupNow,
            ),
            _tile(
              Icons.tune_rounded,
              AppColors.tileBlue,
              'Backup settings',
              status.account!,
              () => _settingsMenu(status),
            ),
          ],
        ),
      ],
    );
  }

  static String _problemMessage(BackupErrorCode problem) => switch (problem) {
    BackupErrorCode.storageFull => 'Backup paused: your Google Drive is full. Free up some space, then tap here.',
    BackupErrorCode.replacedElsewhere =>
      'Backup paused: your backup was changed from another phone. Tap to choose what to keep.',
    _ => 'Backup paused: PowerHub lost access to your Google account. Tap to connect again.',
  };

  AppListTile _tile(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) => AppListTile(
    leading: AppIconBadge(icon: icon, color: color, size: AppSpacing.listIcon),
    title: title,
    subtitle: subtitle,
    subtitleMaxLines: 3,
    trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
    onTap: _busy ? null : onTap,
  );
}
