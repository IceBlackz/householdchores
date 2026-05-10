import 'package:pocketbase/pocketbase.dart';

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.icon,
    required this.created,
  });

  final String id;
  final String name;
  final String icon;
  final DateTime created;

  factory Room.fromRecord(RecordModel record) {
    final createdStr = record.getStringValue('created');
    return Room(
      id: record.id,
      name: record.getStringValue('name'),
      icon: record.getStringValue('icon'),
      created: createdStr.isNotEmpty
          ? DateTime.parse(createdStr)
          : DateTime.now(),
    );
  }
}
