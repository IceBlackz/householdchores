import 'package:pocketbase/pocketbase.dart';

/// Service for interacting with PocketBase servers.
/// Supports multiple servers by accepting a house URL.
class PocketBaseService {
  /// Singleton instance.
  PocketBaseService._internal();
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;

  /// PocketBase client instance.
  late final PocketBase client;

  /// Initializes the service with a house URL.
  /// @param baseUrl The PocketBase server URL (from the active house).
  void init(String baseUrl) {
    client = PocketBase(baseUrl);
  }

  /// Re-initializes with a new URL (used when switching houses).
  void setBaseUrl(String baseUrl) {
    client = PocketBase(baseUrl);
  }

  /// Builds the URL for a file stored in PocketBase.
  String fileUrl(String collectionId, String recordId, String filename) {
    return '${client.baseURL}/api/files/$collectionId/$recordId/$filename';
  }
}
