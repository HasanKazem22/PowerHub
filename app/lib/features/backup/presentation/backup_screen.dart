import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/backup/backup_service.dart';
import '../../../data/backup/drive_backup_service.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../shared/layouts/app_page.dart';
import '../../../shared/widgets/cards/app_info_banner.dart';
import '../../../shared/widgets/dialogs/app_confirm_dialog.dart';
import '../../../shared/widgets/indicators/app_icon_badge.dart';
import '../../../shared/widgets/lists/app_list_card.dart';
import '../../../shared/widgets/lists/app_list_tile.dart';
import '../../../shared/widgets/misc/section_header.dart';
import 'widgets/google_backup_section.dart';

final _lastFileBackupProvider = StreamProvider<DateTime?>(
  (ref) => ref
      .watch(databaseProvider)
      .watchSetting(SettingKeys.lastBackupAt)
      .map((v) => v == null ? null : DateTime.tryParse(v)?.toLocal()),
);

/// Backup & restore: automatic backup to the user's Google Drive ([GoogleBackupSection]), a backup file to keep
/// anywhere.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  AppDatabase get _db => ref.read(databaseProvider);

  // ── Backup file ────────────────────────────────────────

  Future<void> _saveBackup() => _run(() async {
    final json = await BackupService(_db).exportJson();
    final name = 'PowerHub-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
    final result = await _share(utf8.encode(json), name, 'application/json', 'PowerHub backup');
    if (result.status != ShareResultStatus.dismissed) {
      await _db.setSetting(SettingKeys.lastBackupAt, DateTime.now().toUtc().toIso8601String());
      _snack('Backup ready. Keep it somewhere safe.');
    }
  });

  Future<void> _restoreFile() => _run(() async {
    final text = await _pickText(['json']);
    if (text == null) return;
    final int rows;
    try {
      rows = BackupService.countRows(text);
    } on BackupFormatException catch (e) {
      _snack(e.message);
      return;
    }
    if (!mounted) return;
    final ok = await showAppConfirmDialog(
      context,
      title: 'Replace everything with this backup?',
      message:
          'All projects on this phone are replaced by the backup ($rows items). '
          'Anything saved after the backup was made will be lost.',
      confirmLabel: 'Restore',
    );
    if (!ok) return;
    final summary = await BackupService(_db).restore(text);
    final when = summary.exportedAt == null
        ? ''
        : ' from ${DateFormat('d MMM yyyy').format(summary.exportedAt!.toLocal())}';
    _snack('Restored ${summary.rows} items$when.');
  });

  // ── Helpers ────────────────────────────────────────────

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on BackupFormatException catch (e) {
      _snack(e.message);
    } catch (e) {
      debugPrint('PowerHub: backup action failed: $e');
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<ShareResult> _share(List<int> bytes, String name, String mime, String subject) {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(Uint8List.fromList(bytes), mimeType: mime, name: name)],
        fileNameOverrides: [name],
        subject: subject,
      ),
    );
  }

  Future<String?> _pickText(List<String> extensions) async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: extensions);
    if (picked.isEmpty) return null;
    return utf8.decode(await picked.single.readAsBytes(), allowMalformed: true);
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
    final fileLast = ref.watch(_lastFileBackupProvider).value;
    final drive = ref.watch(driveBackupStatusProvider).value;
    final backupAvailable = ref.watch(driveBackupServiceProvider) != null;
    final driveOn = backupAvailable && (drive?.on ?? false);
    final last = [
      fileLast,
      if (driveOn) drive?.lastBackupAt,
    ].whereType<DateTime>().fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final stale = !driveOn && (last == null || DateTime.now().difference(last).inDays >= 30);

    AppListTile action(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) => AppListTile(
      leading: AppIconBadge(icon: icon, color: color, size: AppSpacing.listIcon),
      title: title,
      subtitle: subtitle,
      subtitleMaxLines: 3,
      trailing: Icon(Icons.chevron_right_rounded, color: muted),
      onTap: _busy ? null : onTap,
    );

    return AppPage(
      title: 'Backup & restore',
      children: [
        AppInfoBanner(
          type: stale ? AppBannerType.warning : AppBannerType.success,
          icon: stale ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
          message: switch ((driveOn, last)) {
            (true, null) => 'Google backup is on. The first backup is on its way.',
            (true, final DateTime at) => 'Backed up to Google Drive. Last backup: ${_format(at)}.',
            (false, null) =>
              'No backup yet. Your projects are only on this phone. '
                  '${backupAvailable ? 'Turn on Google backup below.' : 'Save a backup file below.'}',
            (false, final DateTime at) => 'Last backup: ${_format(at)}.${stale ? ' Time for a new one.' : ''}',
          },
        ),
        if (_busy) ...[const SizedBox(height: AppSpacing.md), const LinearProgressIndicator()],
        const SectionHeader('Google Drive backup'),
        const GoogleBackupSection(),
        const SectionHeader('Backup file'),
        AppListCard(
          children: [
            action(
              Icons.backup_outlined,
              AppColors.tileGreen,
              'Save a backup file',
              'Every saved project in one file. Keep it anywhere, or send it to yourself.',
              _saveBackup,
            ),
            action(
              Icons.settings_backup_restore_rounded,
              AppColors.tileBlue,
              'Restore from a backup file',
              'On a new phone, or to go back. Replaces the projects on this phone.',
              _restoreFile,
            ),
          ],
        ),
      ],
    );
  }

  static String _format(DateTime at) => DateFormat('d MMM yyyy, h:mm a').format(at);
}
