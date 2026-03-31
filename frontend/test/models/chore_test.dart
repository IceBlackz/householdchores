import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:frontend/models/app_user.dart';
import 'package:frontend/models/chore.dart';
import 'package:frontend/constants/app_constants.dart';

RecordModel _userRecord({
  String id = 'user1',
  String name = '',
  String email = 'test@example.com',
}) {
  return RecordModel.fromJson({
    'id': id,
    'collectionId': '_pb_users_auth_',
    'collectionName': 'users',
    'name': name,
    'email': email,
  });
}

RecordModel _choreRecord({
  String id = 'chore1',
  String title = 'Clean Toilet',
  String description = 'Scrub thoroughly',
  int intervalDesiredDays = 7,
  int intervalMaxDays = 14,
  String season = 'All',
  Map<String, dynamic>? defaultAssigneeJson,
  Map<String, dynamic>? onetimeOnlyAssigneeJson,
}) {
  final expand = <String, dynamic>{};
  if (defaultAssigneeJson != null) expand['default_assignee'] = defaultAssigneeJson;
  if (onetimeOnlyAssigneeJson != null) expand['onetimeonly_assignee'] = onetimeOnlyAssigneeJson;

  return RecordModel.fromJson({
    'id': id,
    'collectionId': 'pbc_1145403802',
    'collectionName': 'chores',
    'title': title,
    'description': description,
    'interval_desired_days': intervalDesiredDays,
    'interval_max_days': intervalMaxDays,
    'season': season,
    'default_assignee': defaultAssigneeJson?['id'] ?? '',
    'onetimeonly_assignee': onetimeOnlyAssigneeJson?['id'] ?? '',
    'created': '2024-01-01 10:00:00.000Z',
    if (expand.isNotEmpty) 'expand': expand,
  });
}

Map<String, dynamic> _userJson({
  String id = 'u1',
  String name = '',
  String email = 'user@home.local',
}) => {
      'id': id,
      'collectionId': '_pb_users_auth_',
      'collectionName': 'users',
      'name': name,
      'email': email,
    };

void main() {
  group('AppUser', () {
    test('displayName returns name when non-empty', () {
      final user = AppUser.fromRecord(_userRecord(name: 'Alice'));
      expect(user.displayName, 'Alice');
    });

    test('displayName falls back to email when name is empty', () {
      final user = AppUser.fromRecord(_userRecord(name: '', email: 'alice@home.com'));
      expect(user.displayName, 'alice@home.com');
    });
  });

  group('Chore.fromRecord', () {
    test('parses basic fields correctly', () {
      final chore = Chore.fromRecord(_choreRecord());
      expect(chore.id, 'chore1');
      expect(chore.title, 'Clean Toilet');
      expect(chore.description, 'Scrub thoroughly');
      expect(chore.intervalDesiredDays, 7);
      expect(chore.intervalMaxDays, 14);
      expect(chore.season, 'All');
    });

    test('activeAssignee is null when no assignees set', () {
      final chore = Chore.fromRecord(_choreRecord());
      expect(chore.activeAssignee, isNull);
      expect(chore.hasOneTimeOverride, isFalse);
      expect(chore.activeAssigneeName, AppConstants.unassignedLabel);
      expect(chore.activeAssigneeId, '');
    });

    test('activeAssignee uses defaultAssignee when no override', () {
      final chore = Chore.fromRecord(
        _choreRecord(defaultAssigneeJson: _userJson(id: 'u1', name: 'Bob')),
      );
      expect(chore.hasOneTimeOverride, isFalse);
      expect(chore.activeAssigneeId, 'u1');
      expect(chore.activeAssigneeName, 'Bob');
    });

    test('onetimeOnlyAssignee overrides defaultAssignee', () {
      final chore = Chore.fromRecord(
        _choreRecord(
          defaultAssigneeJson: _userJson(id: 'u1', name: 'Bob'),
          onetimeOnlyAssigneeJson: _userJson(id: 'u2', name: 'Alice'),
        ),
      );
      expect(chore.hasOneTimeOverride, isTrue);
      expect(chore.activeAssigneeId, 'u2');
      expect(chore.activeAssigneeName, 'Alice');
    });

    test('activeAssigneeName falls back to email when user name is empty', () {
      final chore = Chore.fromRecord(
        _choreRecord(
          defaultAssigneeJson: _userJson(id: 'u1', name: '', email: 'bob@home.local'),
        ),
      );
      expect(chore.activeAssigneeName, 'bob@home.local');
    });
  });
}
