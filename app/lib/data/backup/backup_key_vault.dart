import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'backup_crypto.dart';

/// This phone's copy of the [BackupKey], so automatic backups run without asking for the backup password.
abstract interface class BackupKeyVault {
  Future<BackupKey?> read();

  Future<void> write(BackupKey key);

  Future<void> clear();
}

/// [BackupKeyVault] in the platform's secure storage (Android Keystore, iOS Keychain). Never in the app database:
/// the database goes into backup files, the key must not.
class SecureBackupKeyVault implements BackupKeyVault {
  SecureBackupKeyVault({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _entry = 'powerhub.backup_key.v1';

  @override
  Future<BackupKey?> read() async {
    try {
      final raw = await _storage.read(key: _entry);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return BackupKey(BackupKey.idFromHex(json['id'] as String), base64.decode(json['secret'] as String));
    } catch (_) {
      // Damaged or unreadable (e.g. the Keystore key is gone): the Backup screen then offers to restore or
      // replace the backup, which writes a fresh key.
      await clear().catchError((_) {});
      return null;
    }
  }

  @override
  Future<void> write(BackupKey key) =>
      _storage.write(key: _entry, value: jsonEncode({'id': key.idHex, 'secret': base64.encode(key.secret)}));

  @override
  Future<void> clear() => _storage.delete(key: _entry);
}

/// In memory, for tests.
class MemoryBackupKeyVault implements BackupKeyVault {
  BackupKey? key;

  @override
  Future<BackupKey?> read() async => key;

  @override
  Future<void> write(BackupKey value) async => key = value;

  @override
  Future<void> clear() async => key = null;
}
