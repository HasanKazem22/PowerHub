import 'dart:convert';
import 'package:archive/archive.dart' show GZipDecoder, GZipEncoder;
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import 'backup_exceptions.dart';
import 'backup_service.dart';

/// The secret that locks every backup of one Google account: a random 256-bit AES key with a random id.
///
/// Envelope design (like WhatsApp's encrypted backups): backups are encrypted with this key; the key itself is
/// stored in Google Drive in a small [BackupKeyFile], either as it is or locked with the user's backup password.
/// Changing the password only re-locks the key, never the backups. The phone keeps its copy in secure storage
/// (BackupKeyVault), so automatic backups never ask for the password.
class BackupKey {
  BackupKey(this.id, this.secret) : assert(id.length == idLength && secret.length == 32);

  factory BackupKey.generate() {
    final random = Random.secure();
    Uint8List bytes(int n) => Uint8List.fromList(List.generate(n, (_) => random.nextInt(256)));
    return BackupKey(bytes(idLength), bytes(32));
  }

  static const idLength = 16;

  /// Written in front of every backup, so a backup can be matched to its key without opening it.
  final Uint8List id;
  final Uint8List secret;

  String get idHex => _hex(id);

  static Uint8List idFromHex(String hex) {
    if (hex.length != idLength * 2) throw const BackupFormatException('This backup key is damaged.');
    return Uint8List.fromList([for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)]);
  }
}

/// How the [BackupKey] is kept in Google Drive.
enum KeyProtection {
  /// Protected by the user's Google account: only PowerHub can read its hidden Drive folder.
  none,

  /// Also locked with a backup password that only the user knows (end-to-end).
  password,
}

/// Argon2id settings for turning a password into a key. Stored in the key file, so they can be raised later
/// without breaking older backups.
class KdfParams {
  const KdfParams({required this.memoryKiB, required this.iterations, required this.parallelism});

  /// OWASP's recommended minimum for Argon2id (m=19 MiB, t=2, p=1): about half a second on a phone.
  static const recommended = KdfParams(memoryKiB: 19 * 1024, iterations: 2, parallelism: 1);

  final int memoryKiB;
  final int iterations;
  final int parallelism;

  Map<String, Object> toJson() => {'alg': 'argon2id', 'm': memoryKiB, 't': iterations, 'p': parallelism};

  static KdfParams fromJson(Map<String, dynamic> json) {
    if (json['alg'] != 'argon2id') throw const BackupFormatException('This backup needs a newer PowerHub.');
    return KdfParams(
      memoryKiB: (json['m'] as num).toInt(),
      iterations: (json['t'] as num).toInt(),
      parallelism: (json['p'] as num).toInt(),
    );
  }
}

/// The key file in Google Drive (`powerhub-key.json`): which key the backups use, and the key itself, either
/// as it is ([KeyProtection.none]) or encrypted with a key derived from the backup password.
class BackupKeyFile {
  const BackupKeyFile._({
    required this.keyId,
    required this.protection,
    required this.payload,
    required this.createdAt,
    this.salt,
    this.kdf,
  });

  static const format = 'powerhub-backup-key';
  static const version = 1;
  static const minPasswordLength = 8;

  /// [BackupKey.idHex].
  final String keyId;
  final KeyProtection protection;

  /// The key ([KeyProtection.none]) or nonce · ciphertext · tag ([KeyProtection.password]).
  final Uint8List payload;
  final Uint8List? salt;
  final KdfParams? kdf;
  final DateTime createdAt;

  static BackupKeyFile plain(BackupKey key, {DateTime? now}) => BackupKeyFile._(
    keyId: key.idHex,
    protection: KeyProtection.none,
    payload: key.secret,
    createdAt: (now ?? DateTime.now()).toUtc(),
  );

  static Future<BackupKeyFile> protect(
    BackupKey key,
    String password, {
    KdfParams kdf = KdfParams.recommended,
    DateTime? now,
  }) async {
    if (password.length < minPasswordLength) {
      throw ArgumentError('The backup password needs at least $minPasswordLength characters.');
    }
    final salt = BackupKey.generate().id; // 16 random bytes
    final kek = await _deriveKek(password, salt, kdf);
    final box = await _aes.encrypt(key.secret, secretKey: kek, aad: _wrapAad(key.idHex));
    return BackupKeyFile._(
      keyId: key.idHex,
      protection: KeyProtection.password,
      payload: box.concatenation(),
      salt: salt,
      kdf: kdf,
      createdAt: (now ?? DateTime.now()).toUtc(),
    );
  }

  /// The key. A [KeyProtection.password] file needs [password]; a wrong one throws
  /// [BackupErrorCode.wrongPassword].
  Future<BackupKey> unlock({String? password}) async {
    final id = BackupKey.idFromHex(keyId);
    if (protection == KeyProtection.none) return BackupKey(id, payload);
    if (password == null || password.isEmpty) {
      throw const BackupException(BackupErrorCode.wrongPassword, 'Enter your backup password.');
    }
    try {
      final box = SecretBox.fromConcatenation(
        payload,
        nonceLength: _aes.nonceLength,
        macLength: _aes.macAlgorithm.macLength,
      );
      final kek = await _deriveKek(password, salt!, kdf!);
      final secret = await _aes.decrypt(box, secretKey: kek, aad: _wrapAad(keyId));
      return BackupKey(id, Uint8List.fromList(secret));
    } on SecretBoxAuthenticationError {
      throw const BackupException(BackupErrorCode.wrongPassword, 'Wrong backup password. Please try again.');
    }
  }

  String encode() => jsonEncode({
    'format': format,
    'version': version,
    'keyId': keyId,
    'protection': protection.name,
    'payload': base64.encode(payload),
    if (salt != null) 'salt': base64.encode(salt!),
    if (kdf != null) 'kdf': kdf!.toJson(),
    'createdAt': createdAt.toIso8601String(),
  });

  static BackupKeyFile decode(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic> || json['format'] != format) throw const FormatException();
      if ((json['version'] as num? ?? 0) > version) {
        throw const BackupFormatException('This backup was made by a newer PowerHub. Update the app first.');
      }
      final protection = KeyProtection.values.byName(json['protection'] as String);
      return BackupKeyFile._(
        keyId: json['keyId'] as String,
        protection: protection,
        payload: base64.decode(json['payload'] as String),
        salt: json['salt'] == null ? null : base64.decode(json['salt'] as String),
        kdf: json['kdf'] == null ? null : KdfParams.fromJson(json['kdf'] as Map<String, dynamic>),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    } on BackupFormatException {
      rethrow;
    } catch (_) {
      throw const BackupFormatException('The backup key in Google Drive is damaged.');
    }
  }

  static List<int> _wrapAad(String keyId) => utf8.encode('powerhub-key-v1:$keyId');
}

/// Locks a backup before it leaves the phone, and opens it again.
///
/// The backup JSON is compressed (gzip), then encrypted with AES-256-GCM using the [BackupKey]. GCM also detects
/// any change to the file. File layout: `"BTB2"` (4) · key id (16) · nonce (12) · ciphertext · tag (16); the
/// magic and key id are authenticated too.
abstract final class BackupCrypto {
  static final _magic = ascii.encode('BTB2');
  static final _headerLength = _magic.length + BackupKey.idLength;
  static final _minLength = _headerLength + 12 + 16;

  static Future<Uint8List> seal(String json, BackupKey key) async {
    final header = [..._magic, ...key.id];
    final box = await _aes.encrypt(
      const GZipEncoder().encodeBytes(utf8.encode(json)),
      secretKey: SecretKey(key.secret),
      aad: header,
    );
    return Uint8List.fromList([...header, ...box.concatenation()]);
  }

  /// The id of the key a backup was locked with ([BackupKey.idHex]).
  static String keyIdOf(List<int> file) {
    _checkHeader(file);
    return _hex(file.sublist(_magic.length, _headerLength));
  }

  /// The backup JSON. Throws [BackupFormatException] for a file that isn't a PowerHub backup, was changed, or
  /// was locked with another key.
  static Future<String> open(List<int> file, BackupKey key) async {
    _checkHeader(file);
    if (keyIdOf(file) != key.idHex) throw const BackupFormatException(_otherKey);
    try {
      final box = SecretBox.fromConcatenation(
        file.sublist(_headerLength),
        nonceLength: _aes.nonceLength,
        macLength: _aes.macAlgorithm.macLength,
      );
      final packed = await _aes.decrypt(box, secretKey: SecretKey(key.secret), aad: file.sublist(0, _headerLength));
      return utf8.decode(const GZipDecoder().decodeBytes(packed));
    } on SecretBoxAuthenticationError {
      throw const BackupFormatException('This backup is damaged and cannot be opened.');
    }
  }

  static const _otherKey = 'This backup belongs to an older backup key and cannot be opened.';

  static void _checkHeader(List<int> file) {
    if (file.length < _minLength || !listEquals(file.sublist(0, _magic.length), _magic)) {
      throw const BackupFormatException('This is not a PowerHub backup.');
    }
  }
}

final _aes = AesGcm.with256bits();

String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Argon2id is deliberately slow (about half a second): run it off the UI thread so screens stay smooth.
Future<SecretKey> _deriveKek(String password, List<int> salt, KdfParams kdf) async {
  final bytes = await compute(_argon2id, (utf8.encode(password), salt, kdf.memoryKiB, kdf.iterations, kdf.parallelism));
  return SecretKey(bytes);
}

Future<List<int>> _argon2id((List<int>, List<int>, int, int, int) input) async {
  final (password, salt, memory, iterations, parallelism) = input;
  final key = await Argon2id(
    memory: memory,
    iterations: iterations,
    parallelism: parallelism,
    hashLength: 32,
  ).deriveKey(secretKey: SecretKey(password), nonce: salt);
  return key.extractBytes();
}
