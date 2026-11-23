import 'dart:convert';

import 'package:powerhub/data/backup/backup_crypto.dart';
import 'package:powerhub/data/backup/backup_exceptions.dart';
import 'package:powerhub/data/backup/backup_key_vault.dart';
import 'package:powerhub/data/backup/backup_service.dart';
import 'package:powerhub/data/backup/drive_backup_service.dart';
import 'package:powerhub/data/backup/drive_backup_store.dart';
import 'package:powerhub/data/backup/google_drive_account.dart';
import 'package:powerhub/data/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_drive.dart';

/// Argon2id kept tiny so the tests run fast; the app uses [KdfParams.recommended].
const _fastKdf = KdfParams(memoryKiB: 64, iterations: 1, parallelism: 1);

/// One phone: its own database, secure storage and Google Sign-In, sharing [drive] (the Google account).
class _Phone {
  _Phone(FakeDrive drive, {String name = 'Phone'})
    : db = AppDatabase(NativeDatabase.memory()),
      google = FakeGoogle(),
      vault = MemoryBackupKeyVault() {
    service = DriveBackupService(
      db: db,
      drive: google,
      vault: vault,
      deviceName: () async => name,
      storeFor: drive.storeFor,
      kdf: _fastKdf,
    );
  }

  final AppDatabase db;
  final FakeGoogle google;
  final MemoryBackupKeyVault vault;
  late final DriveBackupService service;

  GoogleIdentity get identity => const GoogleIdentity(email: 'rahim@gmail.com', displayName: 'Rahim Ahmed');

  Future<String?> setting(String key) => db.getSetting(key);

  /// Saves a project named [note] (the data a backup carries). [kw] keeps the old call sites readable.
  Future<void> addExpense(int kw, [String note = '']) async {
    await db.saveProject(
      name: note.isEmpty ? 'Project $kw' : note,
      module: 'load',
      inputs: {'kw': kw},
      summary: '$kw kW',
    );
    // Distinct timestamps, so newest-first order is stable.
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }

  /// Saved project names, newest first (only the ones saved with a name).
  Future<List<String>> notes() async => [
    for (final p in await db.watchProjects().first)
      if (!p.name.startsWith('Project ')) p.name,
  ];
}

void main() {
  // "Two phones" are two separate in-memory databases here, on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('BackupCrypto', () {
    const json = '{"format":"powerhub-backup","tables":{"accounts":[{"name":"bKash"}]}}';
    final key = BackupKey.generate();

    test('a sealed backup opens with the same key, and names its key', () async {
      final sealed = await BackupCrypto.seal(json, key);
      expect(utf8.decode(sealed, allowMalformed: true), isNot(contains('bKash')));
      expect(BackupCrypto.keyIdOf(sealed), key.idHex);
      expect(await BackupCrypto.open(sealed, key), json);
    });

    test('another key cannot open it', () async {
      final sealed = await BackupCrypto.seal(json, key);
      expect(() => BackupCrypto.open(sealed, BackupKey.generate()), throwsA(isA<BackupFormatException>()));
      // Same id, different secret (a forged key file): still refused.
      expect(
        () => BackupCrypto.open(sealed, BackupKey(key.id, BackupKey.generate().secret)),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('a changed file is refused, including its header', () async {
      final body = await BackupCrypto.seal(json, key);
      body[body.length - 20] ^= 1;
      expect(() => BackupCrypto.open(body, key), throwsA(isA<BackupFormatException>()));
    });

    test('something that is not a backup is refused', () {
      expect(
        () => BackupCrypto.open(utf8.encode('hello, this is not it at all.....'), key),
        throwsA(isA<BackupFormatException>()),
      );
      expect(() => BackupCrypto.keyIdOf([1, 2, 3]), throwsA(isA<BackupFormatException>()));
    });
  });

  group('BackupKeyFile', () {
    final key = BackupKey.generate();

    test('without a password it opens directly', () async {
      final file = BackupKeyFile.decode(utf8.encode(BackupKeyFile.plain(key).encode()));
      expect(file.protection, KeyProtection.none);
      final opened = await file.unlock();
      expect(opened.idHex, key.idHex);
      expect(opened.secret, key.secret);
    });

    test('with a password it opens only with that password', () async {
      final protected = await BackupKeyFile.protect(key, 'my secret phrase', kdf: _fastKdf);
      final file = BackupKeyFile.decode(utf8.encode(protected.encode()));
      expect(file.protection, KeyProtection.password);
      expect(protected.encode(), isNot(contains(base64.encode(key.secret))));
      expect((await file.unlock(password: 'my secret phrase')).secret, key.secret);
      await expectLater(
        file.unlock(password: 'wrong phrase!'),
        throwsA(isA<BackupException>().having((e) => e.code, 'code', BackupErrorCode.wrongPassword)),
      );
      await expectLater(file.unlock(), throwsA(isA<BackupException>()));
    });

    test('short passwords are refused', () {
      expect(() => BackupKeyFile.protect(key, 'short', kdf: _fastKdf), throwsArgumentError);
    });

    test('a damaged or newer key file is refused', () {
      expect(() => BackupKeyFile.decode(utf8.encode('{"hello":1}')), throwsA(isA<BackupFormatException>()));
      final newer = jsonDecode(BackupKeyFile.plain(key).encode()) as Map<String, dynamic>..['version'] = 99;
      expect(
        () => BackupKeyFile.decode(utf8.encode(jsonEncode(newer))),
        throwsA(isA<BackupFormatException>().having((e) => e.message, 'message', contains('newer'))),
      );
    });
  });

  group('DriveBackupService', () {
    late FakeDrive drive;
    late _Phone a;

    setUp(() {
      drive = FakeDrive();
      a = _Phone(drive, name: 'Samsung A54');
    });
    tearDown(() => a.db.close());

    _Phone newPhone() {
      final phone = _Phone(drive, name: 'Pixel 8');
      addTearDown(phone.db.close);
      return phone;
    }

    test('turning on: an encrypted backup with its details goes to Drive, and backup is on', () async {
      await a.addExpense(500, 'Bazar');
      final (identity, remote) = await a.service.connect();
      expect(remote.exists, isFalse);
      await a.service.startNew(identity);

      final file = drive.backups.single;
      expect(file.name, startsWith(GoogleDriveStore.prefix));
      expect(file.properties[BackupFileProperties.device], 'Samsung A54');
      expect(int.parse(file.properties[BackupFileProperties.items]!), greaterThan(0));
      expect(utf8.decode(drive.files[file.id]!.bytes, allowMalformed: true), isNot(contains('Bazar')));
      expect(BackupKeyFile.decode(drive.keyFile!).protection, KeyProtection.none);
      expect(a.vault.key!.idHex, file.properties[BackupFileProperties.keyId]);

      expect(await a.setting(SettingKeys.driveAccount), 'rahim@gmail.com');
      expect(await a.setting(SettingKeys.driveAuto), '1');
      // No name typed yet: Home greets with the Google name.
      expect(await a.setting(SettingKeys.userName), 'Rahim Ahmed');
    });

    test('automatic backup uploads only when the data changed', () async {
      await a.service.startNew(a.identity);
      expect(await a.service.runAutomatic(), isFalse, reason: 'nothing changed since turning on');
      await a.addExpense(200);
      expect(await a.service.runAutomatic(), isTrue);
      expect(await a.service.runAutomatic(), isFalse);
      expect(drive.backups, hasLength(2));
    });

    test('automatic backup does nothing when off, or when turned off for automatic', () async {
      await a.addExpense(100);
      expect(await a.service.runAutomatic(), isFalse);
      expect(drive.backups, isEmpty);

      await a.service.startNew(a.identity);
      await a.service.setAutomatic(false);
      await a.addExpense(100);
      expect(await a.service.runAutomatic(), isFalse);
      expect(drive.backups, hasLength(1));
      await a.service.backupNow(); // "Back up now" still works.
      expect(drive.backups, hasLength(2));
    });

    test('only the newest 3 backups are kept', () async {
      await a.service.startNew(a.identity);
      for (var i = 0; i < 4; i++) {
        await a.addExpense(10 + i);
        await a.service.backupNow();
      }
      expect(drive.backups, hasLength(DriveBackupService.keep));
    });

    test('a new phone gets everything back, keeps its own settings, and continues the backups', () async {
      await a.addExpense(1250, 'বাজার');
      await a.db.setSetting(SettingKeys.userName, 'Rahim');
      await a.service.startNew(a.identity);

      final b = newPhone();
      await b.addExpense(1, 'only on B');
      final (identity, remote) = await b.service.connect();
      expect(remote.exists, isTrue);
      expect(remote.needsPassword, isFalse);
      expect(remote.device, 'Samsung A54');
      final summary = await b.service.restore(identity);

      expect(summary.rows, greaterThan(0));
      expect(await b.notes(), contains('বাজার'));
      expect(await b.notes(), isNot(contains('only on B')));
      expect(await b.setting(SettingKeys.userName), 'Rahim');
      expect(await b.setting(SettingKeys.driveAccount), 'rahim@gmail.com');
      expect(await b.service.runAutomatic(), isFalse, reason: 'B holds exactly what is in Drive');

      await b.addExpense(300, 'from B');
      expect(await b.service.runAutomatic(), isTrue);
      final c = newPhone();
      await c.service.restore(c.identity);
      expect(await c.notes(), contains('from B'));
    });

    test('restoring from a Google account without a backup says so', () async {
      await expectLater(
        a.service.restore(a.identity),
        throwsA(isA<BackupException>().having((e) => e.code, 'code', BackupErrorCode.noBackup)),
      );
    });

    test('a password locks the backup with a new key; the old backups go', () async {
      await a.addExpense(700, 'secret');
      await a.service.startNew(a.identity);
      final oldKey = a.vault.key!.idHex;

      await a.service.setPassword('correct horse battery');
      expect(await a.setting(SettingKeys.drivePassword), '1');
      final keyFile = BackupKeyFile.decode(drive.keyFile!);
      expect(keyFile.protection, KeyProtection.password);
      expect(keyFile.keyId, isNot(oldKey), reason: 'the old key was readable in Drive');
      expect(drive.backups.map((f) => f.properties[BackupFileProperties.keyId]), everyElement(keyFile.keyId));

      final b = newPhone();
      final (_, remote) = await b.service.connect();
      expect(remote.needsPassword, isTrue);
      await expectLater(
        b.service.restore(b.identity, password: 'wrong horse'),
        throwsA(isA<BackupException>().having((e) => e.code, 'code', BackupErrorCode.wrongPassword)),
      );
      expect(await b.notes(), isNot(contains('secret')), reason: 'a wrong password changes nothing');
      await b.service.restore(b.identity, password: 'correct horse battery');
      expect(await b.notes(), contains('secret'));
      expect(await b.setting(SettingKeys.drivePassword), '1');
    });

    test('changing the password needs the current one and keeps the backups', () async {
      await a.service.startNew(a.identity);
      await a.service.setPassword('first password');
      final backups = drive.backups.map((f) => f.id).toList();

      await expectLater(
        a.service.setPassword('second password', current: 'not it at all'),
        throwsA(isA<BackupException>().having((e) => e.code, 'code', BackupErrorCode.wrongPassword)),
      );
      await a.service.setPassword('second password', current: 'first password');
      expect(drive.backups.map((f) => f.id), backups, reason: 'only the key is re-locked');

      final keyFile = BackupKeyFile.decode(drive.keyFile!);
      await expectLater(keyFile.unlock(password: 'first password'), throwsA(isA<BackupException>()));
      expect((await keyFile.unlock(password: 'second password')).idHex, a.vault.key!.idHex);
    });

    test('removing the password needs the current one', () async {
      await a.service.startNew(a.identity);
      await a.service.setPassword('first password');
      await expectLater(a.service.removePassword('nope nope'), throwsA(isA<BackupException>()));
      await a.service.removePassword('first password');
      expect(BackupKeyFile.decode(drive.keyFile!).protection, KeyProtection.none);
      expect(await a.setting(SettingKeys.drivePassword), '0');
      final b = newPhone();
      await b.service.restore(b.identity);
    });

    test('if Drive fails half-way through setting a password, the old backup still restores', () async {
      await a.addExpense(900, 'safe');
      await a.service.startNew(a.identity);
      drive.failKeyWrite = true;
      await expectLater(a.service.setPassword('a new password'), throwsA(isA<BackupException>()));
      drive.failKeyWrite = false;

      final b = newPhone();
      await b.service.restore(b.identity);
      expect(await b.notes(), contains('safe'));
      // And the first phone carries on with its old key; the orphan upload is cleaned up.
      await a.addExpense(1);
      expect(await a.service.runAutomatic(), isTrue);
      expect(
        drive.backups.map((f) => f.properties[BackupFileProperties.keyId]),
        everyElement(BackupKeyFile.decode(drive.keyFile!).keyId),
      );
    });

    test('a phone never overwrites a backup another phone replaced', () async {
      await a.service.startNew(a.identity);
      final b = newPhone();
      await b.addExpense(42, 'B data');
      await b.service.startNew(b.identity); // "Replace with this phone's data".

      await a.addExpense(5, 'A data');
      expect(await a.service.runAutomatic(), isFalse);
      expect(await a.setting(SettingKeys.driveProblem), BackupErrorCode.replacedElsewhere.name);
      final c = newPhone();
      await c.service.restore(c.identity);
      expect(await c.notes(), contains('B data'));
      expect(await c.notes(), isNot(contains('A data')));
    });

    test('Google needing the user pauses automatic backup until "Back up now"', () async {
      await a.service.startNew(a.identity);
      a.google.silent = null;
      await a.addExpense(5);
      expect(await a.service.runAutomatic(), isFalse);
      expect(await a.setting(SettingKeys.driveProblem), BackupErrorCode.needsSignIn.name);

      await a.service.backupNow(); // Interactive: Google's screens fix it.
      expect(await a.setting(SettingKeys.driveProblem), isNull);
    });

    test('offline is retried quietly, without bothering the user', () async {
      await a.service.startNew(a.identity);
      drive.failWith = const BackupException.offline();
      await a.addExpense(5);
      expect(await a.service.runAutomatic(), isFalse);
      expect(await a.setting(SettingKeys.driveProblem), isNull);
      drive.failWith = null;
      expect(await a.service.runAutomatic(), isTrue);
    });

    test('turning off keeps the backup unless asked to delete it', () async {
      await a.service.startNew(a.identity);
      await a.service.turnOff();
      expect(drive.backups, hasLength(1));
      expect(a.vault.key, isNull);
      expect(await a.setting(SettingKeys.driveAccount), isNull);
      expect(a.google.disconnects, 1);

      await a.service.startNew(a.identity);
      await a.service.turnOff(deleteBackups: true);
      expect(drive.backups, isEmpty);
      expect(drive.keyFile, isNull);
    });

    test('backups never contain this phone\'s own settings, and the fingerprint ignores when it was made', () async {
      await a.service.startNew(a.identity);
      final first = await BackupService(a.db).snapshot();
      expect(first.json, isNot(contains(SettingKeys.driveAccount)));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect((await BackupService(a.db).snapshot()).fingerprint, first.fingerprint);
    });
  });
}
