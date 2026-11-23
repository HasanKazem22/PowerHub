import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/backup/drive_backup_service.dart';
import '../../../data/providers.dart';

/// Runs the automatic Google Drive backup ([DriveBackupService.runAutomatic]) while the app is open:
///
/// * [_afterChangeDelay] after the user stops adding or changing things (one backup for a burst of edits),
/// * a few seconds after the app opens, and whenever it comes back to the screen,
/// * when the app goes to the background with changes not backed up yet.
///
/// Each run uploads only when the data really changed since the last backup, so these checks are cheap, and it
/// is silent: offline or Google problems are retried at the next trigger. Wraps the tab pages (AppShell).
class AutoBackup extends ConsumerStatefulWidget {
  const AutoBackup({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AutoBackup> createState() => _AutoBackupState();
}

class _AutoBackupState extends ConsumerState<AutoBackup> with WidgetsBindingObserver {
  static const _startDelay = Duration(seconds: 8);
  static const _afterChangeDelay = Duration(minutes: 2);

  StreamSubscription<void>? _changes;
  Timer? _timer;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Not at once: the first seconds belong to showing the app.
    _schedule(_startDelay);
    _changes = ref.read(databaseProvider).tableUpdates(const TableUpdateQuery.any()).listen((_) {
      _pending = true;
      _schedule(_afterChangeDelay);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _changes?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _schedule(const Duration(seconds: 2));
      case AppLifecycleState.paused when _pending:
        // Leaving with unsaved changes: back up now, while the system still lets the app run briefly.
        _run();
      default:
    }
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _run);
  }

  Future<void> _run() async {
    _timer?.cancel();
    final service = ref.read(driveBackupServiceProvider);
    if (service == null) return;
    _pending = false;
    await service.runAutomatic();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
