import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/misc.dart' show ProviderException;

/// The real cause of an error.
///
/// Riverpod wraps an error in [ProviderException] when it passes from one
/// provider to another (database → accounts), which on its own only says
/// "ProviderException". This unwraps it down to the original error.
Object rootError(Object error) {
  var e = error;
  while (e is ProviderException) {
    e = e.exception;
  }
  return e;
}

/// Technical description of [error], for logs and "copy error".
String describeError(Object error, {int maxLength = 400}) {
  final text = rootError(error).toString().trim();
  return text.length <= maxLength ? text : '${text.substring(0, maxLength)}…';
}

/// What to tell the user when the local database cannot be opened.
String databaseErrorMessage(Object error) {
  if (kIsWeb) {
    return 'PowerHub is a phone app, and the browser version is missing its database files. '
        'Run it on an Android phone or emulator instead.';
  }
  return 'Could not open your data on this phone. Please close and reopen the app.';
}
