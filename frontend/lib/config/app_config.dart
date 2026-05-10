import 'package:flutter/foundation.dart' show kIsWeb;
import 'runtime_config.dart';

class AppConfig {
  /// The current app version. Updated automatically by release.ps1.
  static const String appVersion = '1.0.0';

  /// Minimum server MAJOR version this app requires.
  static const int minServerMajorVersion = 1;

  /// Returns the backend URL.
  /// On web: uses config.js when set. Otherwise:
  /// - local dev web port 9011 maps to backend port 9010
  /// - normal/proxied installs use the same origin, e.g. https://chores.example.com
  /// On native: uses BACKEND_URL dart-define, or falls back to localhost.
  static String get backendUrl {
    if (kIsWeb) {
      return webBackendUrlFor(Uri.base, configuredUrl: runtimeBackendUrl());
    }
    return String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://127.0.0.1:9010',
    );
  }

  static String webBackendUrlFor(Uri base, {String? configuredUrl}) {
    final configured = configuredUrl?.trim().replaceAll(RegExp(r'/+$'), '');
    if (configured != null && configured.isNotEmpty) return configured;

    if (_usesLocalWebPort(base)) {
      return _origin(base.replace(port: 9010));
    }

    return _origin(base);
  }

  static bool _usesLocalWebPort(Uri base) {
    if (base.port != 9011) return false;
    return base.host == 'localhost' ||
        base.host == '127.0.0.1' ||
        base.host == '::1';
  }

  static String _origin(Uri uri) {
    final origin = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
    return origin.replaceAll(RegExp(r'/+$'), '');
  }
}
