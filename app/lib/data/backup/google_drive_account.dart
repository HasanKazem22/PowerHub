import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_config.dart';
import 'backup_exceptions.dart';

/// The Google account backups go to.
class GoogleIdentity {
  const GoogleIdentity({required this.email, this.displayName});
  final String email;
  final String? displayName;
}

/// Access to the user's Google Drive for backups.
abstract interface class DriveAccount {
  /// Asks the user to pick a Google account and allow PowerHub to keep its backups in Drive. Must be called from
  /// a tap (it shows Google's screens).
  Future<GoogleIdentity> connect();

  /// An access token without showing anything (automatic backups); null when the user must connect again.
  Future<String?> silentAccessToken();

  /// An access token, showing Google's screens if needed (call from a tap).
  Future<String> accessToken();

  /// Signs out of Google in PowerHub and removes its Drive access.
  Future<void> disconnect();
}

/// [DriveAccount] with Google Sign-In, asking only for the `drive.appdata` scope: PowerHub can see its own
/// hidden backup folder and nothing else in the user's Drive. No PowerHub server is involved.
class GoogleDriveAccount implements DriveAccount {
  GoogleDriveAccount();

  static const scopes = ['https://www.googleapis.com/auth/drive.appdata'];
  static Future<void>? _initialized;

  GoogleSignIn get _google => GoogleSignIn.instance;

  Future<void> _init() => _initialized ??= _google.initialize(
    serverClientId: AppConfig.googleServerClientId.isEmpty ? null : AppConfig.googleServerClientId,
    clientId: AppConfig.googleIosClientId.isEmpty ? null : AppConfig.googleIosClientId,
  );

  @override
  Future<GoogleIdentity> connect() async {
    try {
      await _init();
      final account = await _google.authenticate(scopeHint: scopes);
      await account.authorizationClient.authorizeScopes(scopes);
      return GoogleIdentity(email: account.email, displayName: account.displayName);
    } on GoogleSignInException catch (e) {
      throw _describe(e);
    }
  }

  @override
  Future<String?> silentAccessToken() async {
    try {
      await _init();
      final account = await _google.attemptLightweightAuthentication();
      final client = account?.authorizationClient ?? _google.authorizationClient;
      return (await client.authorizationForScopes(scopes))?.accessToken;
    } on GoogleSignInException {
      return null;
    }
  }

  @override
  Future<String> accessToken() async {
    final silent = await silentAccessToken();
    if (silent != null) return silent;
    try {
      return (await _google.authorizationClient.authorizeScopes(scopes)).accessToken;
    } on GoogleSignInException catch (e) {
      throw _describe(e);
    }
  }

  @override
  Future<void> disconnect() async {
    await _init();
    try {
      await _google.disconnect();
    } on GoogleSignInException {
      await _google.signOut();
    }
  }

  static BackupException _describe(GoogleSignInException e) => switch (e.code) {
    GoogleSignInExceptionCode.canceled => const BackupException(BackupErrorCode.canceled, 'Google was not connected.'),
    GoogleSignInExceptionCode.clientConfigurationError || GoogleSignInExceptionCode.providerConfigurationError =>
      const BackupException(BackupErrorCode.notSetUp, "Google backup isn't set up in this version of PowerHub yet."),
    _ => BackupException(BackupErrorCode.google, "Couldn't connect to Google. ${e.description ?? ''}".trim()),
  };
}

/// [DriveAccount] in the browser (the web preview, for testing). Google has no "pick an account" sign-in call on
/// the web, so connecting opens Google's consent popup for `drive.appdata` directly, and the account's email comes
/// from Drive itself. Browser tokens last an hour and can't be renewed silently, so automatic backup pauses after
/// that until the next "Back up now" (fine for testing; the phone app has no such limit).
///
/// Google Cloud: the Web client needs `http://localhost:5000` under Authorized JavaScript origins, and the app must
/// run on that port (`--web-port=5000`, set in the PowerHub run configuration).
class WebGoogleDriveAccount implements DriveAccount {
  WebGoogleDriveAccount({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 20)));

  final Dio _dio;
  static Future<void>? _initialized;
  String? _token;
  DateTime? _expiresAt;

  GoogleSignIn get _google => GoogleSignIn.instance;

  Future<void> _init() => _initialized ??= _google.initialize(clientId: AppConfig.googleServerClientId);

  @override
  Future<GoogleIdentity> connect() async {
    final token = await _authorize();
    try {
      final reply = await _dio.get<Map<String, dynamic>>(
        'https://www.googleapis.com/drive/v3/about',
        queryParameters: {'fields': 'user(emailAddress,displayName)'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final user = reply.data?['user'] as Map<String, dynamic>?;
      return GoogleIdentity(
        email: user?['emailAddress'] as String? ?? 'Google account',
        displayName: user?['displayName'] as String?,
      );
    } on DioException {
      return const GoogleIdentity(email: 'Google account');
    }
  }

  @override
  Future<String?> silentAccessToken() async {
    final expires = _expiresAt;
    if (_token != null && expires != null && DateTime.now().isBefore(expires)) return _token;
    return null;
  }

  @override
  Future<String> accessToken() async => await silentAccessToken() ?? await _authorize();

  @override
  Future<void> disconnect() async {
    _token = null;
    _expiresAt = null;
    try {
      await _init();
      await _google.disconnect();
    } catch (_) {
      // Nothing to revoke.
    }
  }

  Future<String> _authorize() async {
    try {
      await _init();
      final authz = await _google.authorizationClient.authorizeScopes(GoogleDriveAccount.scopes);
      _token = authz.accessToken;
      // Google's browser tokens last 60 minutes; renew a little early.
      _expiresAt = DateTime.now().add(const Duration(minutes: 55));
      return authz.accessToken;
    } on GoogleSignInException catch (e) {
      throw GoogleDriveAccount._describe(e);
    }
  }
}
