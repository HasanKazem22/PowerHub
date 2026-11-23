import 'dart:typed_data';

import 'package:powerhub/data/backup/backup_exceptions.dart';
import 'package:powerhub/data/backup/drive_backup_store.dart';
import 'package:powerhub/data/backup/google_drive_account.dart';

/// Google Drive's hidden app folder, in memory. One instance is "the Google account": every phone that connects
/// to it sees the same files.
class FakeDrive implements BackupStore {
  final files = <String, ({RemoteBackupFile meta, Uint8List bytes})>{};
  Uint8List? keyFile;
  final tokensSeen = <String>[];
  var _next = 0;
  DateTime clock = DateTime.utc(2026, 11, 22, 9);

  /// Makes every call fail like this (e.g. offline), until cleared.
  BackupException? failWith;

  /// Makes writing the key file fail (to check nothing is lost half-way).
  bool failKeyWrite = false;

  /// A store for one phone's token source.
  BackupStore Function(Future<String> Function() token) get storeFor =>
      (token) => _TokenStore(this, token);

  List<RemoteBackupFile> get backups =>
      files.values.map((f) => f.meta).toList()..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

  @override
  Future<List<RemoteBackupFile>> list() async => backups;

  @override
  Future<RemoteBackupFile> upload(String name, Uint8List bytes, {Map<String, String> properties = const {}}) async {
    clock = clock.add(const Duration(minutes: 1));
    final meta = RemoteBackupFile(
      id: 'f${_next++}',
      name: name,
      modifiedAt: clock,
      size: bytes.length,
      properties: Map.of(properties),
    );
    files[meta.id] = (meta: meta, bytes: Uint8List.fromList(bytes));
    return meta;
  }

  @override
  Future<Uint8List> download(String id) async => files[id]!.bytes;

  @override
  Future<void> delete(String id) async => files.remove(id);

  @override
  Future<Uint8List?> readKeyFile() async => keyFile;

  @override
  Future<void> writeKeyFile(Uint8List bytes) async {
    if (failKeyWrite) throw const BackupException(BackupErrorCode.google, 'Google Drive had a problem.');
    keyFile = Uint8List.fromList(bytes);
  }

  @override
  Future<void> deleteKeyFile() async => keyFile = null;
}

/// Asks for a token before every call, like [GoogleDriveStore], so token problems surface the same way.
class _TokenStore implements BackupStore {
  _TokenStore(this._drive, this._token);
  final FakeDrive _drive;
  final Future<String> Function() _token;

  Future<FakeDrive> _ready() async {
    _drive.tokensSeen.add(await _token());
    if (_drive.failWith != null) throw _drive.failWith!;
    return _drive;
  }

  @override
  Future<List<RemoteBackupFile>> list() async => (await _ready()).list();

  @override
  Future<RemoteBackupFile> upload(String name, Uint8List bytes, {Map<String, String> properties = const {}}) async =>
      (await _ready()).upload(name, bytes, properties: properties);

  @override
  Future<Uint8List> download(String id) async => (await _ready()).download(id);

  @override
  Future<void> delete(String id) async => (await _ready()).delete(id);

  @override
  Future<Uint8List?> readKeyFile() async => (await _ready()).readKeyFile();

  @override
  Future<void> writeKeyFile(Uint8List bytes) async => (await _ready()).writeKeyFile(bytes);

  @override
  Future<void> deleteKeyFile() async => (await _ready()).deleteKeyFile();
}

/// Google Sign-In on one phone.
class FakeGoogle implements DriveAccount {
  FakeGoogle({this.email = 'rahim@gmail.com', this.displayName = 'Rahim Ahmed'});

  final String email;
  final String? displayName;

  /// The token automatic backups get; null when Google needs the user again.
  String? silent = 'google-token';
  int connects = 0;
  int disconnects = 0;

  @override
  Future<GoogleIdentity> connect() async {
    connects++;
    silent ??= 'google-token';
    return GoogleIdentity(email: email, displayName: displayName);
  }

  @override
  Future<String?> silentAccessToken() async => silent;

  @override
  Future<String> accessToken() async => silent ?? 'interactive-token';

  @override
  Future<void> disconnect() async {
    disconnects++;
    silent = null;
  }
}
