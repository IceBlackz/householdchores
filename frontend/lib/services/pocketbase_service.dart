import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  PocketBaseService._internal();
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;

  late final PocketBase client;

  void init(String baseUrl) {
    client = PocketBase(baseUrl);
  }

  /// Builds the URL for a file stored in PocketBase.
  String fileUrl(String collectionId, String recordId, String filename) {
    return '${client.baseURL}/api/files/$collectionId/$recordId/$filename';
  }
}
