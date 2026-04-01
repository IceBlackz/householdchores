import 'package:pocketbase/pocketbase.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.isAdmin = false,
  });

  final String id;
  final String name;
  final String email;
  final bool isAdmin;

  String get displayName => name.isNotEmpty ? name : email;

  factory AppUser.fromRecord(RecordModel record) {
    return AppUser(
      id:      record.id,
      name:    record.getStringValue('name'),
      email:   record.getStringValue('email'),
      isAdmin: record.getBoolValue('is_admin'),
    );
  }
}