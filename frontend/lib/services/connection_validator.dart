import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for validating PocketBase server connections.
/// Checks if a server is a valid householdchores server.
class ConnectionValidator {
  /// Default timeout for connection checks.
  static const int defaultTimeout = 5000; // 5 seconds

  /// Default retry limit for connection checks.
  static const int defaultRetryLimit = 2;

  /// Validates a house configuration.
  /// Returns true if the server is a valid householdchores server.
  /// Returns false if validation fails.
  static Future<bool> validateHouse(
    String url, {
    int timeoutMs = defaultTimeout,
    int retryLimit = defaultRetryLimit,
  }) async {
    try {
      // Check 1: URL format
      final uri = Uri.parse(url);
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return false;
      }

      // Check 2: Server is reachable
      final isReachable = await _checkServerReachability(
        uri,
        timeoutMs: timeoutMs,
        retryLimit: retryLimit,
      );
      if (!isReachable) {
        return false;
      }

      // Check 3: Server exposes the app-specific version endpoint.
      if (!await _checkVersionEndpoint(uri, timeoutMs: timeoutMs)) {
        return false;
      }

      return true;
    } catch (e) {
      // Log error but don't crash
      // print('House validation failed: $e');
      return false;
    }
  }

  /// Checks if the server is reachable.
  static Future<bool> _checkServerReachability(
    Uri uri, {
    int timeoutMs = defaultTimeout,
    int retryLimit = defaultRetryLimit,
  }) async {
    final healthUri = _buildEndpointUri(uri, 'api/health');

    for (int attempt = 0; attempt <= retryLimit; attempt++) {
      final client = http.Client();
      try {
        final response = await client
            .get(healthUri)
            .timeout(Duration(milliseconds: timeoutMs));

        // PocketBase health endpoint returns 200 for healthy servers.
        return response.statusCode == 200;
      } catch (_) {
        if (attempt == retryLimit) {
          return false;
        }
        // Retry on network errors
        await Future.delayed(Duration(milliseconds: timeoutMs ~/ 2));
      } finally {
        client.close();
      }
    }
    return false;
  }

  /// Checks whether the app-specific version endpoint is exposed.
  static Future<bool> _checkVersionEndpoint(
    Uri uri, {
    int timeoutMs = defaultTimeout,
  }) async {
    final client = http.Client();
    try {
      final versionUri = _buildEndpointUri(uri, 'api/householdchores/version');
      final response = await client
          .get(versionUri)
          .timeout(Duration(milliseconds: timeoutMs));

      if (response.statusCode != 200) {
        return false;
      }

      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> &&
          (body['version'] as String?)?.isNotEmpty == true;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  static Uri _buildEndpointUri(Uri baseUri, String endpointPath) {
    final pathSegments = [
      ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
      ...endpointPath.split('/').where((segment) => segment.isNotEmpty),
    ];

    return baseUri.replace(
      path: '/${pathSegments.join('/')}',
      query: null,
      fragment: null,
    );
  }

  /// Gets a validation error message for a given error.
  static String getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    }

    if (error is Map<String, dynamic>) {
      final message = error['message'] ?? 'Unknown error';
      final code = error['code'] ?? 'UNKNOWN';
      return '$message (Error code: $code)';
    }

    return error.toString();
  }
}
