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
  static Future<bool> validateHouse(String url, {
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
      final response = await _checkServerReachability(uri, timeoutMs: timeoutMs);
      if (!response) {
        return false;
      }

      // Check 3: Server has householdchores-specific collections
      final collections = await _checkCollections(uri, timeoutMs: timeoutMs);
      if (collections == null) {
        return false;
      }

      // Check 4: Server has the required collections (chores, users, chore_logs)
      final requiredCollections = ['chores', 'users', 'chore_logs'];
      final missingCollections = requiredCollections.where((c) => !collections.contains(c));
      if (missingCollections.isNotEmpty) {
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
  }) async {
    for (int attempt = 0; attempt <= defaultRetryLimit; attempt++) {
      try {
        final client = http.Client();
        final response = await client
            .get(uri)
            .timeout(Duration(milliseconds: timeoutMs));
        client.close();

        // PocketBase returns 200 for valid servers
        return response.statusCode == 200;
      } catch (e) {
        if (attempt == defaultRetryLimit) {
          return false;
        }
        // Retry on network errors
        await Future.delayed(Duration(milliseconds: timeoutMs ~/ 2));
      }
    }
    return false;
  }

  /// Checks if the server has householdchores-specific collections.
  /// Returns null if the server is not a householdchores server.
  static Future<List<String>?> _checkCollections(
    Uri uri, {
    int timeoutMs = defaultTimeout,
  }) async {
    try {
      final client = http.Client();
      final response = await client
          .get(Uri.parse('${uri.toString()}/api/collections'))
          .timeout(Duration(milliseconds: timeoutMs));
      client.close();

      if (response.statusCode != 200) {
        return null;
      }

      final collections = jsonDecode(response.body) as List<dynamic>;
      return collections
          .map((c) => c['name'] as String)
          .where((name) => name != '_pb_users_auth_')
          .toList();
    } catch (e) {
      return null;
    }
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
