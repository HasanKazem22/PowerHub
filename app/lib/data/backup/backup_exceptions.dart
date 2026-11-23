/// Why a Google Drive backup or restore didn't work, with a message to show the user as it is.
///
/// Callers switch on [code]; [message] is plain language for the screen.
class BackupException implements Exception {
  const BackupException(this.code, this.message, {this.status});

  const BackupException.offline()
    : code = BackupErrorCode.offline,
      message = 'No internet connection. PowerHub will back up when you are online.',
      status = null;

  final BackupErrorCode code;
  final String message;

  /// HTTP status from Google, when there was one.
  final int? status;

  @override
  String toString() => message;
}

enum BackupErrorCode {
  /// The user closed Google's screens: nothing to show.
  canceled,

  /// This build has no Google client ID (see AppConfig).
  notSetUp,

  /// Google needs the user again (access removed, signed out on the phone). Fix: connect again.
  needsSignIn,

  /// No connection or Google unreachable. Fix: wait.
  offline,

  /// The user's Google Drive is full.
  storageFull,

  /// No PowerHub backup in this Google account.
  noBackup,

  /// The backup password is wrong.
  wrongPassword,

  /// The backup in Drive was replaced from another phone (new key): this phone must restore or replace it.
  replacedElsewhere,

  /// Any other problem from Google.
  google,
}
