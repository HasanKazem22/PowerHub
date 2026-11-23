import 'package:flutter/foundation.dart';

/// Build settings. The defaults are PowerHub's own Google Cloud project, so every build (Run, Build APK, a release)
/// has Google backup without extra steps. `--dart-define` (or `--dart-define-from-file=config/dev.json`) overrides
/// them, e.g. to test with another Google Cloud project.
///
/// | Setting | What |
/// |---|---|
/// | `GOOGLE_SERVER_CLIENT_ID` | The **Web** OAuth client ID of the Google Cloud project. Android's Google sign-in needs it. Empty: Google backup is hidden |
/// | `GOOGLE_IOS_CLIENT_ID` | The iOS OAuth client ID (iPhone builds only; not created yet) |
///
/// Client IDs are not secrets: Google designs them to be public, they are built into every copy of the app, and an
/// Android app can only use them when it has PowerHub's package name and signing key (the SHA-1 registered in
/// Google Cloud). Never put a client *secret* here. PowerHub has no server: data stays on the phone, and the
/// optional backup goes straight to the user's own Google Drive.
abstract final class AppConfig {
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '1058350190282-iqr5vmklegf1l14jjkodatp8hlivleqe.apps.googleusercontent.com',
  );
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Google Drive backup can be offered in this build. In the browser (a test preview) it uses the same Web
  /// client ID, which then needs `http://localhost:5000` as an Authorized JavaScript origin.
  static bool get driveBackupEnabled {
    if (kIsWeb) return googleServerClientId.isNotEmpty;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => googleServerClientId.isNotEmpty,
      TargetPlatform.iOS => googleIosClientId.isNotEmpty,
      _ => false,
    };
  }
}
