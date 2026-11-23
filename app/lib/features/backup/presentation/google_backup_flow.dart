import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/backup/backup_exceptions.dart';
import '../../../data/backup/backup_service.dart';
import '../../../data/backup/drive_backup_service.dart';
import '../../../data/backup/google_drive_account.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_info_banner.dart';
import '../../../shared/widgets/dialogs/app_bottom_sheet.dart';
import '../../../shared/widgets/dialogs/app_confirm_dialog.dart';
import '../../../shared/widgets/dialogs/app_progress_dialog.dart';
import '../../../shared/widgets/indicators/app_icon_badge.dart';
import '../../../shared/widgets/lists/app_list_card.dart';
import '../../../shared/widgets/lists/app_list_tile.dart';
import 'widgets/backup_password_sheets.dart';

/// The steps of turning on Google backup and restoring from it, shared by Settings, the Backup screen and the
/// welcome screen. Every function shows its own errors and returns quietly when the user cancels.
abstract final class GoogleBackupFlow {
  /// "Back up with Google": pick an account; with no backup there, start backing up at once. If a backup is
  /// already there, the user chooses: restore it onto this phone, or replace it with this phone's data.
  static Future<void> turnOn(BuildContext context, WidgetRef ref) async {
    final service = ref.read(driveBackupServiceProvider);
    if (service == null) return;
    final connected = await _guard(context, service.connect);
    if (connected == null || !context.mounted) return;
    final (identity, remote) = connected;

    if (!remote.exists) {
      final ok = await _guard(
        context,
        () => runWithProgress(context, 'Backing up to Google Drive…', () async {
          await service.startNew(identity);
          return true;
        }),
      );
      if (ok != null && context.mounted) _snack(context, 'Backup is on. Your data is safe in ${identity.email}.');
      return;
    }

    final choice = await _showBackupFound(context, identity, remote, allowReplace: true);
    if (!context.mounted) return;
    switch (choice) {
      case _Choice.restore:
        await _restore(context, ref, identity, remote);
      case _Choice.replace:
        await _replace(context, ref, identity);
      case null:
        await _cancel(ref); // Nothing was saved: just let go of the Google account.
    }
  }

  /// "Restore from Google Drive" on a new phone (welcome screen) or from the Backup screen. With backup already
  /// on, restores from the connected account without asking for one. Returns true when data was restored.
  static Future<bool> restore(BuildContext context, WidgetRef ref) async {
    final service = ref.read(driveBackupServiceProvider);
    if (service == null) return false;
    final account = ref.read(driveBackupStatusProvider).value?.account;
    final connected = account != null
        ? await _guard(context, () async => (GoogleIdentity(email: account), await service.inspect()))
        : await _guard(context, service.connect);
    if (connected == null || !context.mounted) return false;
    final (identity, remote) = connected;
    if (!remote.exists) {
      await _cancel(ref);
      if (context.mounted) {
        _snack(context, 'There is no PowerHub backup in ${identity.email}. Try the Google account you used before.');
      }
      return false;
    }
    final choice = await _showBackupFound(context, identity, remote, allowReplace: false);
    if (choice != _Choice.restore || !context.mounted) {
      await _cancel(ref);
      return false;
    }
    return _restore(context, ref, identity, remote);
  }

  /// Backup is on but was re-keyed from another phone: overwrite it with this phone's data (after asking).
  static Future<void> replaceWithThisPhone(BuildContext context, WidgetRef ref) async {
    final account = ref.read(driveBackupStatusProvider).value?.account;
    if (account == null) return;
    await _replace(context, ref, GoogleIdentity(email: account));
  }

  /// Asks for the password when there is one (again after a wrong one), then restores.
  static Future<bool> _restore(
    BuildContext context,
    WidgetRef ref,
    GoogleIdentity identity,
    RemoteBackupInfo remote,
  ) async {
    final service = ref.read(driveBackupServiceProvider)!;
    String? subtitle = 'The password you set for your PowerHub backup.';
    while (true) {
      if (!context.mounted) return false;
      String? password;
      if (remote.needsPassword) {
        final answer = await askBackupPassword(
          context,
          title: 'Enter backup password',
          subtitle: subtitle,
          confirmLabel: 'Restore',
          offerForgot: true,
        );
        if (!context.mounted) return false;
        if (answer == null) {
          await _cancel(ref);
          return false;
        }
        if (answer.forgot) {
          await _forgotPassword(context, ref, identity);
          return false;
        }
        password = answer.password;
      }
      if (!context.mounted) return false;
      try {
        final summary = await runWithProgress(
          context,
          'Restoring your data…',
          () => service.restore(identity, password: password),
        );
        if (context.mounted) _snack(context, 'Restored ${summary.rows} items. Welcome back!');
        return true;
      } on BackupException catch (e) {
        if (e.code != BackupErrorCode.wrongPassword) {
          await _cancel(ref);
          if (context.mounted) _show(context, e);
          return false;
        }
        subtitle = 'That password is not right. Try again.';
      } on BackupFormatException catch (e) {
        await _cancel(ref);
        if (context.mounted) _snack(context, e.message);
        return false;
      }
    }
  }

  /// Tapped "Forgot password?": offer to start over (the old backup can't be opened without the password).
  static Future<void> _forgotPassword(BuildContext context, WidgetRef ref, GoogleIdentity identity) async {
    final startOver = await showAppConfirmDialog(
      context,
      title: 'Forgot your backup password?',
      message:
          'Without it, the backup in ${identity.email} cannot be opened, by you or by PowerHub. '
          "You can start a new backup with this phone's data instead. The old backup will be deleted.",
      confirmLabel: 'Start new backup',
    );
    if (!context.mounted) return;
    if (startOver) {
      await _replace(context, ref, identity, confirmed: true);
    } else {
      await _cancel(ref);
    }
  }

  static Future<void> _replace(
    BuildContext context,
    WidgetRef ref,
    GoogleIdentity identity, {
    bool confirmed = false,
  }) async {
    final service = ref.read(driveBackupServiceProvider)!;
    final ok =
        confirmed ||
        await showAppConfirmDialog(
          context,
          title: 'Replace the backup?',
          message:
              "The backup in ${identity.email} will be deleted and replaced with this phone's data. "
              'This cannot be undone.',
          confirmLabel: 'Replace',
        );
    if (!context.mounted) return;
    if (!ok) {
      await _cancel(ref);
      return;
    }
    final done = await _guard(
      context,
      () => runWithProgress(context, 'Backing up to Google Drive…', () async {
        await service.startNew(identity);
        return true;
      }),
    );
    if (done != null && context.mounted) _snack(context, 'Backup is on. Your data is safe in ${identity.email}.');
  }

  static Future<_Choice?> _showBackupFound(
    BuildContext context,
    GoogleIdentity identity,
    RemoteBackupInfo remote, {
    required bool allowReplace,
  }) => showAppBottomSheet<_Choice>(
    context,
    title: 'Backup found',
    subtitle: 'In ${identity.email}',
    child: _BackupFoundView(remote: remote, allowReplace: allowReplace),
  );

  /// The user backed out before anything was saved. If backup wasn't on before, let go of the Google account
  /// that was just picked; if it was on, leave everything as it was.
  static Future<void> _cancel(WidgetRef ref) async {
    if (_isOn(ref)) return;
    await ref.read(driveBackupServiceProvider)?.turnOff();
  }

  static bool _isOn(WidgetRef ref) => ref.read(driveBackupStatusProvider).value?.on ?? false;

  /// Runs [action]; shows its error and returns null on failure (nothing for a cancelled Google screen).
  static Future<T?> _guard<T>(BuildContext context, Future<T> Function() action) async {
    try {
      return await action();
    } on BackupException catch (e) {
      if (context.mounted) _show(context, e);
    } on BackupFormatException catch (e) {
      if (context.mounted) _snack(context, e.message);
    } catch (e) {
      debugPrint('PowerHub: Google backup failed: $e');
      if (context.mounted) _snack(context, 'Something went wrong. Please try again.');
    }
    return null;
  }

  static void _show(BuildContext context, BackupException e) {
    if (e.code != BackupErrorCode.canceled) _snack(context, e.message);
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _Choice { restore, replace }

class _BackupFoundView extends StatelessWidget {
  const _BackupFoundView({required this.remote, required this.allowReplace});
  final RemoteBackupInfo remote;
  final bool allowReplace;

  @override
  Widget build(BuildContext context) {
    Widget badge(IconData icon, Color color) => AppIconBadge(icon: icon, color: color, size: AppSpacing.listIcon);
    final when = remote.when;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppListCard(
          children: [
            AppListTile(
              leading: badge(Icons.cloud_done_outlined, AppColors.tileGreen),
              title: 'Last backup',
              subtitle: when == null ? 'Unknown' : DateFormat('d MMM yyyy, h:mm a').format(when),
            ),
            if (remote.items != null)
              AppListTile(
                leading: badge(Icons.folder_outlined, AppColors.tileBlue),
                title: '${NumberFormat.decimalPattern('en_IN').format(remote.items)} items',
                subtitle: 'Saved projects and your profile',
              ),
            if (remote.device != null)
              AppListTile(
                leading: badge(Icons.phone_android_rounded, AppColors.tilePurple),
                title: remote.device!,
                subtitle: 'The phone it was made on',
              ),
            if (remote.needsPassword)
              AppListTile(
                leading: badge(Icons.lock_outline_rounded, AppColors.tileOrange),
                title: 'Password protected',
                subtitle: "You'll need your backup password",
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppInfoBanner(
          icon: Icons.info_outline_rounded,
          message: 'Restoring replaces all data on this phone with the backup.',
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Restore',
          icon: Icons.settings_backup_restore_rounded,
          onPressed: () => Navigator.pop(context, _Choice.restore),
        ),
        if (allowReplace) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: "Replace with this phone's data",
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(context, _Choice.replace),
          ),
        ],
      ],
    );
  }
}
