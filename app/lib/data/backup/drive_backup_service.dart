import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/device/device_name.dart';
import '../database.dart';
import '../providers.dart';
import 'backup_crypto.dart';
import 'backup_exceptions.dart';
import 'backup_key_vault.dart';
import 'backup_service.dart';
import 'drive_backup_store.dart';
import 'google_drive_account.dart';

/// What is already in a Google account's Drive, shown before restoring or replacing it.
class RemoteBackupInfo {
  const RemoteBackupInfo({this.latest, this.protection});

  static const none = RemoteBackupInfo();

  /// Newest backup, or null when there is none.
  final RemoteBackupFile? latest;

  /// How the backup key is kept; null when there is no key file.
  final KeyProtection? protection;

  /// A backup that can be restored: a file and its key.
  bool get exists => latest != null && protection != null;
  bool get needsPassword => protection == KeyProtection.password;
  DateTime? get when => latest?.modifiedAt.toLocal();
  int? get items => int.tryParse(latest?.properties[BackupFileProperties.items] ?? '');
  String? get device => latest?.properties[BackupFileProperties.device];
}

/// Free, serverless backup to the user's own Google Drive, like WhatsApp:
///
/// * The user turns it on from Settings ([connect], then [startNew] or [restore]). No PowerHub account.
/// * Each backup is all data ([BackupService]) compressed and encrypted on the phone with the account's
///   [BackupKey], then uploaded to Drive's hidden app folder. The newest [keep] are kept.
/// * The key is stored next to the backups ([BackupKeyFile]), optionally locked with a backup password
///   ([setPassword]), and on the phone in secure storage, so automatic backups ([runAutomatic]) never ask.
/// * On a new phone: [connect] → [restore], with the password if one was set.
///
/// Safety rules: one operation at a time; a new key is published only after a backup locked with it is
/// uploaded, so the key file and the backups in Drive always match; a phone never overwrites a backup that
/// another phone re-keyed ([BackupErrorCode.replacedElsewhere]).
class DriveBackupService {
  DriveBackupService({
    required this._db,
    required this._drive,
    required this._vault,
    Future<String> Function()? deviceName,
    BackupStore Function(Future<String> Function() accessToken)? storeFor,
    DateTime Function()? clock,
    this._kdf = KdfParams.recommended,
  }) : _deviceName = deviceName ?? currentDeviceName,
       _storeFor = storeFor ?? GoogleDriveStore.new,
       _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DriveAccount _drive;
  final BackupKeyVault _vault;
  final Future<String> Function() _deviceName;
  final BackupStore Function(Future<String> Function() accessToken) _storeFor;
  final DateTime Function() _clock;
  final KdfParams _kdf;

  /// Backups kept in Drive (older ones are deleted after each backup).
  static const keep = 3;

  Future<void> _queue = Future.value();

  /// Runs [action] after any operation already running, so two never interleave.
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  BackupStore get _interactive => _storeFor(_drive.accessToken);
  BackupStore get _silent => _storeFor(_silentToken);

  // ── Turning it on ───────────────────────────────────────

  /// Asks the user for a Google account (Google's screens) and looks at what is already in its Drive. Nothing
  /// is saved yet: follow with [startNew] or [restore].
  Future<(GoogleIdentity, RemoteBackupInfo)> connect() async {
    final identity = await _drive.connect();
    return (identity, await _serial(() => _inspect(_interactive)));
  }

  /// What is in the connected account's Drive (may show Google's screens).
  Future<RemoteBackupInfo> inspect() => _serial(() => _inspect(_interactive));

  /// Starts backing up this phone's data to [identity]'s Drive with a new key. Any backup already there is
  /// replaced (the caller has asked the user).
  Future<void> startNew(GoogleIdentity identity) => _serial(() async {
    final store = _interactive;
    // The name is part of the data: set it before the backup, so the backup already has it.
    await _adoptGoogleName(identity);
    await _rekey(store, BackupKey.generate(), password: null);
    await _remember(identity, passwordProtected: false);
  });

  /// Replaces ALL data on this phone with the newest backup in [identity]'s Drive. [password]: when
  /// [RemoteBackupInfo.needsPassword]; a wrong one throws [BackupErrorCode.wrongPassword]. Backups continue
  /// from this phone afterwards.
  Future<RestoreSummary> restore(GoogleIdentity identity, {String? password}) => _serial(() async {
    final store = _interactive;
    final keyFile = await _keyFile(store);
    if (keyFile == null) throw _noBackup;
    final key = await keyFile.unlock(password: password);
    final latest = (await store.list())
        .where((f) => f.properties[BackupFileProperties.keyId] == keyFile.keyId)
        .firstOrNull;
    if (latest == null) throw _noBackup;

    final json = await BackupCrypto.open(await store.download(latest.id), key);
    final summary = await BackupService(_db).restore(json);
    await _vault.write(key);
    await _adoptGoogleName(identity);
    await _remember(identity, passwordProtected: keyFile.protection == KeyProtection.password);
    // The phone now holds exactly what is in Drive: nothing to upload until the user changes something.
    await _db.setSetting(SettingKeys.driveFingerprint, (await BackupService(_db).snapshot()).fingerprint);
    await _db.setSetting(SettingKeys.driveLastBackupAt, latest.modifiedAt.toUtc().toIso8601String());
    return summary;
  });

  // ── Backing up ──────────────────────────────────────────

  /// Backs up now (from a tap: may show Google's screens).
  Future<void> backupNow() => _serial(() => _backup(_interactive, onlyIfChanged: false));

  /// Automatic backup: when backup is on and the data changed since the last one. Never shows anything and
  /// never throws; a problem only the user can fix is saved ([SettingKeys.driveProblem]) for the Backup screen.
  /// Returns whether a backup was uploaded.
  Future<bool> runAutomatic() => _serial(() async {
    try {
      final s = await _db.getSettings([SettingKeys.driveAccount, SettingKeys.driveAuto, SettingKeys.driveProblem]);
      if ((s[SettingKeys.driveAccount] ?? '').isEmpty || s[SettingKeys.driveAuto] == '0') return false;
      // Waiting for the user (restore or replace on this phone): retrying can't help.
      if (s[SettingKeys.driveProblem] == BackupErrorCode.replacedElsewhere.name) return false;
      return await _backup(_silent, onlyIfChanged: true);
    } on BackupException catch (e) {
      if (const {
        BackupErrorCode.needsSignIn,
        BackupErrorCode.replacedElsewhere,
        BackupErrorCode.storageFull,
      }.contains(e.code)) {
        await _db.setSetting(SettingKeys.driveProblem, e.code.name);
      }
      return false; // Offline or a hiccup at Google: try again next time.
    } catch (e) {
      debugPrint('PowerHub: automatic backup failed: $e');
      return false;
    }
  });

  Future<bool> _backup(BackupStore store, {required bool onlyIfChanged}) async {
    final key = await _vault.read();
    final keyFile = await _keyFile(store);
    // Another phone started a new backup (or it was deleted): don't overwrite it from here.
    if (key == null || keyFile == null || keyFile.keyId != key.idHex) {
      throw const BackupException(
        BackupErrorCode.replacedElsewhere,
        'Your Google Drive backup was changed from another phone. Restore it here, or replace it with this '
        "phone's data.",
      );
    }
    final snapshot = await BackupService(_db).snapshot();
    if (onlyIfChanged && snapshot.fingerprint == await _db.getSetting(SettingKeys.driveFingerprint)) return false;
    await _upload(store, snapshot, key);
    await _prune(store, key);
    return true;
  }

  // ── Backup password ─────────────────────────────────────

  /// Locks the backups with a password the user must enter to restore them on a new phone.
  ///
  /// Turning it on uses a new key and a fresh backup: the old key was readable in Drive, so backups made with it
  /// are deleted. Changing an existing password needs [current] and only re-locks the same key.
  Future<void> setPassword(String password, {String? current}) => _serial(() async {
    final store = _interactive;
    final keyFile = await _keyFile(store);
    final key = await _vault.read();
    if (keyFile == null || key == null || keyFile.keyId != key.idHex) {
      throw const BackupException(BackupErrorCode.replacedElsewhere, 'Back up once more, then set the password.');
    }
    if (keyFile.protection == KeyProtection.password) {
      await keyFile.unlock(password: current); // Throws when [current] is wrong.
      await store.writeKeyFile(_bytes((await BackupKeyFile.protect(key, password, kdf: _kdf)).encode()));
    } else {
      await _rekey(store, BackupKey.generate(), password: password);
    }
    await _db.setSetting(SettingKeys.drivePassword, '1');
  });

  /// Removes the backup password after checking [current]. Backups stay protected by the Google account.
  Future<void> removePassword(String current) => _serial(() async {
    final store = _interactive;
    final keyFile = await _keyFile(store);
    if (keyFile == null || keyFile.protection != KeyProtection.password) return;
    final key = await keyFile.unlock(password: current);
    await store.writeKeyFile(_bytes(BackupKeyFile.plain(key, now: _clock()).encode()));
    await _vault.write(key);
    await _db.setSetting(SettingKeys.drivePassword, '0');
  });

  // ── Turning it off ──────────────────────────────────────

  Future<void> setAutomatic(bool on) => _db.setSetting(SettingKeys.driveAuto, on ? '1' : '0');

  /// Stops backing up on this phone and disconnects Google. [deleteBackups]: also removes every PowerHub backup
  /// and the key from Drive (can't be undone).
  Future<void> turnOff({bool deleteBackups = false}) => _serial(() async {
    if (deleteBackups) {
      final store = _interactive;
      for (final file in await store.list()) {
        await store.delete(file.id);
      }
      await store.deleteKeyFile();
    }
    try {
      await _drive.disconnect();
    } catch (_) {
      // Already signed out of Google: nothing to undo.
    }
    await _vault.clear();
    for (final key in [
      SettingKeys.driveAccount,
      SettingKeys.driveFingerprint,
      SettingKeys.drivePassword,
      SettingKeys.driveProblem,
      SettingKeys.driveLastBackupAt,
    ]) {
      await _db.setSetting(key, '');
    }
  });

  // ── Helpers ─────────────────────────────────────────────

  Future<RemoteBackupInfo> _inspect(BackupStore store) async {
    final keyFile = await _keyFile(store);
    final files = await store.list();
    final latest = files.where((f) => f.properties[BackupFileProperties.keyId] == keyFile?.keyId).firstOrNull;
    return RemoteBackupInfo(latest: latest, protection: keyFile?.protection);
  }

  /// Seals the data with [key], uploads it, and only then publishes [key] (locked with [password], if any) and
  /// deletes every backup made with another key. If anything fails before the key is published, Drive still
  /// holds the old key with its own backups; the orphan upload is cleaned up next time.
  Future<void> _rekey(BackupStore store, BackupKey key, {required String? password}) async {
    await _upload(store, await BackupService(_db).snapshot(), key);
    final keyFile = password == null
        ? BackupKeyFile.plain(key, now: _clock())
        : await BackupKeyFile.protect(key, password, kdf: _kdf, now: _clock());
    await store.writeKeyFile(_bytes(keyFile.encode()));
    await _vault.write(key);
    await _db.setSetting(SettingKeys.driveProblem, '');
    await _prune(store, key);
  }

  Future<void> _upload(BackupStore store, BackupSnapshot snapshot, BackupKey key) async {
    final sealed = await BackupCrypto.seal(snapshot.json, key);
    await store.upload(
      '${GoogleDriveStore.prefix}${_stamp(_clock().toUtc())}.btb',
      sealed,
      properties: {
        BackupFileProperties.keyId: key.idHex,
        BackupFileProperties.items: '${snapshot.rows}',
        BackupFileProperties.schema: '${_db.schemaVersion}',
        BackupFileProperties.device: await _deviceName(),
      },
    );
    await _db.setSetting(SettingKeys.driveFingerprint, snapshot.fingerprint);
    await _db.setSetting(SettingKeys.driveLastBackupAt, _clock().toUtc().toIso8601String());
    await _db.setSetting(SettingKeys.driveProblem, '');
  }

  /// Keeps the newest [keep] backups made with [key]; deletes older ones and any made with another key.
  Future<void> _prune(BackupStore store, BackupKey key) async {
    try {
      var kept = 0;
      for (final file in await store.list()) {
        final current = file.properties[BackupFileProperties.keyId] == key.idHex;
        if (current && kept < keep) {
          kept++;
        } else {
          await store.delete(file.id);
        }
      }
    } catch (_) {
      // Old backups are cleaned up next time.
    }
  }

  Future<void> _remember(GoogleIdentity identity, {required bool passwordProtected}) async {
    await _db.setSetting(SettingKeys.driveAccount, identity.email);
    await _db.setSetting(SettingKeys.drivePassword, passwordProtected ? '1' : '0');
    await _db.setSetting(SettingKeys.driveProblem, '');
    if (await _db.getSetting(SettingKeys.driveAuto) == null) await setAutomatic(true);
  }

  /// Greets the user by their Google name on Home if they haven't typed one.
  Future<void> _adoptGoogleName(GoogleIdentity identity) async {
    final name = identity.displayName?.trim() ?? '';
    if (name.isNotEmpty && (await _db.getSetting(SettingKeys.userName) ?? '').trim().isEmpty) {
      await _db.setSetting(SettingKeys.userName, name);
    }
  }

  static Future<BackupKeyFile?> _keyFile(BackupStore store) async {
    final bytes = await store.readKeyFile();
    return bytes == null ? null : BackupKeyFile.decode(bytes);
  }

  Future<String> _silentToken() async {
    final token = await _drive.silentAccessToken();
    if (token == null) {
      throw const BackupException(
        BackupErrorCode.needsSignIn,
        'PowerHub can no longer reach your Google Drive. Connect your Google account again.',
      );
    }
    return token;
  }

  static const _noBackup = BackupException(
    BackupErrorCode.noBackup,
    'There is no PowerHub backup in this Google account. Choose the Google account you used before.',
  );

  static Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

  static String _stamp(DateTime utc) => utc.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
}

/// Google Drive backup, or null when this build can't offer it ([AppConfig.driveBackupEnabled]).
final driveBackupServiceProvider = Provider<DriveBackupService?>((ref) {
  if (!AppConfig.driveBackupEnabled) return null;
  return DriveBackupService(
    db: ref.watch(databaseProvider),
    drive: kIsWeb ? WebGoogleDriveAccount() : GoogleDriveAccount(),
    vault: SecureBackupKeyVault(),
  );
});

/// Google Drive backup as this phone sees it.
class DriveBackupStatus {
  const DriveBackupStatus({
    required this.account,
    required this.automatic,
    required this.lastBackupAt,
    required this.passwordProtected,
    required this.problem,
  });

  /// Google account the backups go to; null when backup is off.
  final String? account;
  final bool automatic;
  final DateTime? lastBackupAt;
  final bool passwordProtected;

  /// Something only the user can fix (connect again, Drive full, replaced elsewhere); null when all is well.
  final BackupErrorCode? problem;

  bool get on => account != null;
}

final driveBackupStatusProvider = StreamProvider<DriveBackupStatus>(
  (ref) => ref
      .watch(databaseProvider)
      .watchSettings([
        SettingKeys.driveAccount,
        SettingKeys.driveAuto,
        SettingKeys.driveLastBackupAt,
        SettingKeys.drivePassword,
        SettingKeys.driveProblem,
      ])
      .map((s) {
        String? value(String key) => (s[key] ?? '').isEmpty ? null : s[key];
        return DriveBackupStatus(
          account: value(SettingKeys.driveAccount),
          automatic: s[SettingKeys.driveAuto] != '0',
          lastBackupAt: DateTime.tryParse(s[SettingKeys.driveLastBackupAt] ?? '')?.toLocal(),
          passwordProtected: s[SettingKeys.drivePassword] == '1',
          problem: BackupErrorCode.values.asNameMap()[value(SettingKeys.driveProblem)],
        );
      }),
);
