import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'connection_validator.dart';

enum VersionStatus {
  compatible,
  appTooOld,
  serverTooOld,
  endpointNotFound,
  checkFailed,
}

class VersionCheckResult {
  const VersionCheckResult({
    required this.status,
    this.serverVersion,
    this.errorMessage,
  });

  final VersionStatus status;
  final String? serverVersion;
  final String? errorMessage;

  bool get isCompatible => status == VersionStatus.compatible;
  bool get isBlocking =>
      status == VersionStatus.appTooOld || status == VersionStatus.serverTooOld;
}

class VersionService {
  static const _timeout = Duration(seconds: 5);

  /// Checks whether the server at [baseUrl] is compatible with this app.
  /// MAJOR versions must match — 1.x ↔ 1.x ✓, 1.x ↔ 2.x ✗
  static Future<VersionCheckResult> checkCompatibility(String baseUrl) async {
    final uri = versionUriFor(baseUrl);
    if (uri == null) {
      return const VersionCheckResult(
        status: VersionStatus.checkFailed,
        errorMessage: 'Invalid server URL',
      );
    }

    try {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 404) {
        return const VersionCheckResult(status: VersionStatus.endpointNotFound);
      }

      if (response.statusCode != 200) {
        return VersionCheckResult(
          status: VersionStatus.checkFailed,
          errorMessage: 'Server returned ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final serverVersion = data['version'] as String? ?? '0.0.0';
      final serverMajor = _major(serverVersion);
      final appMajor = _major(AppConfig.appVersion);

      if (serverMajor > appMajor) {
        return VersionCheckResult(
          status: VersionStatus.appTooOld,
          serverVersion: serverVersion,
        );
      }
      if (serverMajor < appMajor) {
        return VersionCheckResult(
          status: VersionStatus.serverTooOld,
          serverVersion: serverVersion,
        );
      }

      return VersionCheckResult(
        status: VersionStatus.compatible,
        serverVersion: serverVersion,
      );
    } catch (e) {
      return VersionCheckResult(
        status: VersionStatus.checkFailed,
        errorMessage: e.toString(),
      );
    }
  }

  static int _major(String version) {
    try {
      return int.parse(version.split('.').first);
    } catch (_) {
      return 0;
    }
  }

  static Uri? versionUriFor(String baseUrl) {
    final baseUri = Uri.tryParse(baseUrl.trim());
    if (baseUri == null || !baseUri.isAbsolute) return null;
    return ConnectionValidator.buildEndpointUri(
      baseUri,
      'api/householdchores/version',
    );
  }
}
