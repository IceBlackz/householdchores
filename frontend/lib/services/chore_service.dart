import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/chore.dart';
import '../models/chore_log.dart';
import '../models/room.dart';
import 'pocketbase_service.dart';

class ChoreService {
  PocketBase get _pb => PocketBaseService().client;

  // --------------------------------------------------------------------------
  // Chores
  // --------------------------------------------------------------------------

  Future<List<Chore>> fetchChores() async {
    final records = await _pb
        .collection(Collections.chores)
        .getFullList(expand: 'default_assignee,onetimeonly_assignee,room');
    return records.map(Chore.fromRecord).toList();
  }

  Future<void> createChore(Map<String, dynamic> body) async {
    await _pb.collection(Collections.chores).create(body: body);
  }

  Future<void> updateChore(String id, Map<String, dynamic> body) async {
    await _pb.collection(Collections.chores).update(id, body: body);
  }

  Future<void> deleteChore(String id) async {
    await _pb.collection(Collections.chores).delete(id);
  }

  Future<List<Chore>> fetchChoresForRoom(String roomId) async {
    final records = await _pb
        .collection(Collections.chores)
        .getFullList(
          filter: 'room="$roomId"',
          expand: 'default_assignee,onetimeonly_assignee,room',
        );
    return records.map(Chore.fromRecord).toList();
  }

  // --------------------------------------------------------------------------
  // Chore Logs
  // --------------------------------------------------------------------------

  Future<Map<String, ChoreLog>> fetchLatestLogPerChore(
    List<String> choreIds,
  ) async {
    if (choreIds.isEmpty) return {};
    final filter = choreIds.map((id) => 'chore="$id"').join('||');
    final records = await _pb
        .collection(Collections.choreLogs)
        .getFullList(filter: filter, sort: '-created');
    final Map<String, ChoreLog> result = {};
    for (final record in records) {
      final choreId = record.getStringValue('chore');
      result.putIfAbsent(choreId, () => ChoreLog.fromRecord(record));
    }
    return result;
  }

  Future<List<ChoreLog>> fetchLogs(String choreId) async {
    final records = await _pb
        .collection(Collections.choreLogs)
        .getFullList(
          filter: 'chore="$choreId"',
          sort: '-created',
          expand: 'completed_by',
        );
    return records.map(ChoreLog.fromRecord).toList();
  }

  /// [completedBy] defaults to the logged-in user but can be overridden
  /// to mark a chore done on behalf of another household member.
  Future<void> completeChore(
    String choreId, {
    String? completedBy,
    XFile? photoBefore,
    XFile? photoAfter,
    String notes = '',
  }) async {
    final body = <String, dynamic>{
      'chore': choreId,
      'completed_by': completedBy ?? _pb.authStore.record?.id,
      'notes': notes,
    };

    final files = <http.MultipartFile>[];
    if (photoBefore != null) {
      final bytes = await photoBefore.readAsBytes();
      files.add(
        http.MultipartFile.fromBytes(
          'photo_before',
          bytes,
          filename: photoBefore.name,
        ),
      );
    }
    if (photoAfter != null) {
      final bytes = await photoAfter.readAsBytes();
      files.add(
        http.MultipartFile.fromBytes(
          'photo_after',
          bytes,
          filename: photoAfter.name,
        ),
      );
    }

    await _pb
        .collection(Collections.choreLogs)
        .create(body: body, files: files);
    final currentUser = _pb.authStore.record;
    final isCleaner =
        currentUser != null && AppUser.fromRecord(currentUser).hasCleanerRole;
    if (!isCleaner) {
      await _pb
          .collection(Collections.chores)
          .update(choreId, body: {'onetimeonly_assignee': ''});
    }
  }

  // --------------------------------------------------------------------------
  // Users
  // --------------------------------------------------------------------------

  Future<List<AppUser>> fetchUsers() async {
    final records = await _pb
        .collection(Collections.users)
        .getFullList(sort: 'name');
    return records.map(AppUser.fromRecord).toList();
  }

  Future<AppUser> createUser({
    required String name,
    required String email,
    required String password,
    bool isAdmin = false,
    bool isCleaner = false,
  }) async {
    final record = await _pb
        .collection(Collections.users)
        .create(
          body: {
            'name': name,
            'email': email,
            'password': password,
            'passwordConfirm': password,
            'is_admin': isAdmin,
            'is_cleaner': isCleaner,
          },
        );
    return AppUser.fromRecord(record);
  }

  Future<void> updateUser(
    String id, {
    String? name,
    String? email,
    bool? isAdmin,
    bool? isCleaner,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (isAdmin != null) body['is_admin'] = isAdmin;
    if (isCleaner != null) body['is_cleaner'] = isCleaner;
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
      body['passwordConfirm'] = password;
    }
    await _pb.collection(Collections.users).update(id, body: body);
  }

  Future<void> deleteUser(String id) async {
    await _pb.collection(Collections.users).delete(id);
  }

  // --------------------------------------------------------------------------
  // Rooms / focus zones
  // --------------------------------------------------------------------------

  Future<List<Room>> fetchRooms() async {
    final records = await _pb
        .collection(Collections.rooms)
        .getFullList(sort: 'name');
    return records.map(Room.fromRecord).toList();
  }

  Future<Room> createRoom({required String name, String icon = ''}) async {
    final record = await _pb
        .collection(Collections.rooms)
        .create(body: {'name': name, 'icon': icon});
    return Room.fromRecord(record);
  }

  Future<void> updateRoom(
    String id, {
    required String name,
    String icon = '',
  }) async {
    await _pb
        .collection(Collections.rooms)
        .update(id, body: {'name': name, 'icon': icon});
  }

  Future<void> deleteRoom(String id) async {
    final chores = await fetchChoresForRoom(id);
    for (final chore in chores) {
      await updateChore(chore.id, {'room': ''});
    }
    await _pb.collection(Collections.rooms).delete(id);
  }

  Future<Room> duplicateRoomWithChores(Room room, String newName) async {
    final newRoom = await createRoom(name: newName, icon: room.icon);
    final chores = await fetchChoresForRoom(room.id);
    for (final chore in chores) {
      await createChore(choreCopyBody(chore, roomId: newRoom.id));
    }
    return newRoom;
  }

  Map<String, dynamic> choreCopyBody(Chore chore, {String? roomId}) {
    return {
      'title': chore.title,
      'description': chore.description,
      'interval_desired_days': chore.intervalDesiredDays,
      'interval_max_days': chore.intervalMaxDays,
      'interval_unit': chore.intervalUnit,
      'season': chore.season,
      'default_assignee': chore.defaultAssignee?.id ?? '',
      'onetimeonly_assignee': '',
      'cleaner_enabled': chore.cleanerEnabled,
      'season_spring_override': chore.seasonSpringOverride ?? 0,
      'season_summer_override': chore.seasonSummerOverride ?? 0,
      'season_autumn_override': chore.seasonAutumnOverride ?? 0,
      'season_winter_override': chore.seasonWinterOverride ?? 0,
      'room': roomId ?? chore.room?.id ?? '',
    };
  }
}
