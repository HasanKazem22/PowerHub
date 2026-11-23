import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'backup_exceptions.dart';

/// One backup file in the cloud.
class RemoteBackupFile {
  const RemoteBackupFile({
    required this.id,
    required this.name,
    required this.modifiedAt,
    required this.size,
    this.properties = const {},
  });

  final String id;
  final String name;
  final DateTime modifiedAt;
  final int size;

  /// Small details saved with the file ([BackupFileProperties]), readable without downloading it.
  final Map<String, String> properties;
}

/// Keys of [RemoteBackupFile.properties].
abstract final class BackupFileProperties {
  static const items = 'items';
  static const device = 'device';
  static const schema = 'schema';
  static const keyId = 'keyId';
}

/// Where backups and their key file are kept. [GoogleDriveStore] in the app; a fake in tests.
abstract interface class BackupStore {
  /// PowerHub backups, newest first.
  Future<List<RemoteBackupFile>> list();

  Future<RemoteBackupFile> upload(String name, Uint8List bytes, {Map<String, String> properties});

  Future<Uint8List> download(String id);

  Future<void> delete(String id);

  /// The key file's contents, or null when there is none.
  Future<Uint8List?> readKeyFile();

  /// Replaces the key file. The new one is written before the old one is removed, so there is never a moment
  /// without one.
  Future<void> writeKeyFile(Uint8List bytes);

  Future<void> deleteKeyFile();
}

/// Backups in the user's Google Drive, in the hidden app folder ("appDataFolder"). Only PowerHub can see these
/// files: the user can't open or delete them by mistake (Drive → Settings → Manage apps can remove them), and
/// they count towards the user's own Drive storage. Drive REST API v3 with the `drive.appdata` scope only.
class GoogleDriveStore implements BackupStore {
  GoogleDriveStore(this._accessToken, {Dio? dio})
    : _dio =
          dio ??
          Dio(BaseOptions(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(minutes: 2)));

  /// A current Google access token for the `drive.appdata` scope.
  final Future<String> Function() _accessToken;
  final Dio _dio;

  static const prefix = 'powerhub-backup-';
  static const keyFileName = 'powerhub-key.json';
  static const _files = 'https://www.googleapis.com/drive/v3/files';
  static const _upload = 'https://www.googleapis.com/upload/drive/v3/files';
  static const _fields = 'id,name,modifiedTime,size,appProperties';

  @override
  Future<List<RemoteBackupFile>> list() => _find("name contains '$prefix'");

  @override
  Future<RemoteBackupFile> upload(String name, Uint8List bytes, {Map<String, String> properties = const {}}) async {
    const boundary = 'powerhub-backup-boundary';
    final metadata = jsonEncode({
      'name': name,
      'parents': ['appDataFolder'],
      if (properties.isNotEmpty) 'appProperties': properties,
    });
    final body = BytesBuilder(copy: false)
      ..add(utf8.encode('--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n$metadata\r\n'))
      ..add(utf8.encode('--$boundary\r\nContent-Type: application/octet-stream\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));
    final reply = await _request(
      () async => _dio.post<Map<String, dynamic>>(
        _upload,
        queryParameters: {'uploadType': 'multipart', 'fields': _fields},
        data: body.takeBytes(),
        options: (await _auth()).copyWith(contentType: 'multipart/related; boundary=$boundary'),
      ),
    );
    return _file(reply.data!);
  }

  @override
  Future<Uint8List> download(String id) async {
    final reply = await _request(
      () async => _dio.get<List<int>>(
        '$_files/$id',
        queryParameters: {'alt': 'media'},
        options: (await _auth()).copyWith(responseType: ResponseType.bytes),
      ),
    );
    return Uint8List.fromList(reply.data ?? const []);
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _request(() async => _dio.delete<void>('$_files/$id', options: await _auth()));
    } on BackupException catch (e) {
      if (e.status != 404) rethrow; // Already gone.
    }
  }

  @override
  Future<Uint8List?> readKeyFile() async {
    final found = await _find("name = '$keyFileName'");
    return found.isEmpty ? null : download(found.first.id);
  }

  @override
  Future<void> writeKeyFile(Uint8List bytes) async {
    final old = await _find("name = '$keyFileName'");
    await upload(keyFileName, bytes);
    for (final file in old) {
      await delete(file.id);
    }
  }

  @override
  Future<void> deleteKeyFile() async {
    for (final file in await _find("name = '$keyFileName'")) {
      await delete(file.id);
    }
  }

  Future<List<RemoteBackupFile>> _find(String query) async {
    final reply = await _request(
      () async => _dio.get<Map<String, dynamic>>(
        _files,
        queryParameters: {
          'spaces': 'appDataFolder',
          'q': '$query and trashed = false',
          'orderBy': 'modifiedTime desc',
          'fields': 'files($_fields)',
          'pageSize': 100,
        },
        options: await _auth(),
      ),
    );
    return [for (final f in (reply.data?['files'] as List? ?? const [])) _file(f as Map<String, dynamic>)];
  }

  Future<Options> _auth() async => Options(headers: {'Authorization': 'Bearer ${await _accessToken()}'});

  static Future<Response<T>> _request<T>(Future<Response<T>> Function() send) async {
    try {
      return await send();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == null) throw const BackupException.offline();
      throw switch (status) {
        401 => BackupException(BackupErrorCode.needsSignIn, _signInAgain, status: status),
        403 when _reason(e) == 'storageQuotaExceeded' => BackupException(
          BackupErrorCode.storageFull,
          'Your Google Drive is full. Free up some space, then back up again.',
          status: status,
        ),
        403 => BackupException(BackupErrorCode.needsSignIn, _signInAgain, status: status),
        _ => BackupException(
          BackupErrorCode.google,
          'Google Drive had a problem. PowerHub will try again later.',
          status: status,
        ),
      };
    }
  }

  static const _signInAgain = 'PowerHub can no longer reach your Google Drive. Connect your Google account again.';

  /// Google's error reason, e.g. "storageQuotaExceeded".
  static String? _reason(DioException e) {
    final data = e.response?.data;
    if (data is! Map) return null;
    final errors = (data['error'] as Map?)?['errors'] as List?;
    return (errors?.firstOrNull as Map?)?['reason'] as String?;
  }

  static RemoteBackupFile _file(Map<String, dynamic> f) => RemoteBackupFile(
    id: f['id'] as String,
    name: f['name'] as String? ?? '',
    modifiedAt: DateTime.tryParse(f['modifiedTime'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    size: int.tryParse('${f['size'] ?? 0}') ?? 0,
    properties: {for (final e in ((f['appProperties'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'},
  );
}
