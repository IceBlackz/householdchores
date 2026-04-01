import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  /// The current app version. Updated automatically by release.ps1.
  static const String appVersion = '1.0.0';

  /// Minimum server MAJOR version this app requires.
  static const int minServerMajorVersion = 1;

  /// Returns the backend URL.
  /// On web: auto-derives from the page host (same IP, port 9010).
  /// On native: uses BACKEND_URL dart-define, or falls back to localhost.
  static String get backendUrl {
    if (kIsWeb) {
      final base = Uri.base;
      return '${base.scheme}://${base.host}:9010';
    }
    return String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://127.0.0.1:9010',
    );
  }
}