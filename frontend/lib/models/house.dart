import 'package:pocketbase/pocketbase.dart';

/// Model representing a household chore house (PocketBase server).
class House {
  /// House ID.
  final String id;

  /// House name.
  final String name;

  /// PocketBase server URL.
  final String url;

  /// Home Assistant webhook URL (optional).
  final String? haWebhookUrl;

  /// Creates a House from a PocketBase record.
  factory House.fromRecord(RecordModel record) {
    return House(
      id: record.id,
      name: record.data['name'] as String,
      url: record.data['url'] as String,
      haWebhookUrl: record.data['haWebhookUrl'] as String?,
    );
  }

  /// Creates a House from a map.
  factory House.fromMap(Map<String, dynamic> map) {
    return House(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      haWebhookUrl: map['haWebhookUrl'] as String?,
    );
  }

  /// Converts a House to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'haWebhookUrl': haWebhookUrl,
    };
  }

  /// Creates a new House.
  const House({
    required this.id,
    required this.name,
    required this.url,
    this.haWebhookUrl,
  });

  /// Default local house URL.
  static const String defaultLocalHouseUrl = 'http://127.0.0.1:9010';

  /// Default local house name.
  static const String defaultLocalHouseName = 'Home';
}
