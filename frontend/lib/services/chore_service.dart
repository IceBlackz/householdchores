import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/chore.dart';
import '../models/chore_log.dart';

class ChoreService {
  final PocketBase _pb;
  ChoreService(this._pb);

  Future<List<Chore>> fetchChores() async {
    final records = await _pb.collection(Collections.chores).getFullList(
      expand: 'default_assignee,onetimeonly_assignee',
    );
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

  Future<Map<String, ChoreLog>> fetchLatestLogPerChore(List<String> choreIds) async {
    if (choreIds.isEmpty) return {};
    final filter = choreIds.map((id) => 'chore="$id"').join('||');
    final records = await _pb.collection(Collections.choreLogs).getFullList(
      filter: filter,
      sort: '-created',
    );
    final Map<String, ChoreLog> result = {};
    for (final record in records) {
      final choreId = record.getStringValue('chore');
      result.putIfAbsent(choreId, () => ChoreLog.fromRecord(record));
    }
    return result;
  }

  Future<List<ChoreLog>> fetchLogs(String choreId) async {
    final records = await _pb.collection(Collections.choreLogs).getFullList(
      filter: 'chore="$choreId"',
      sort: '-created',
      expand: 'completed_by',
    );
    return records.map(ChoreLog.fromRecord).toList();
  }

  /// Creates a completion log. [completedBy] defaults to the logged-in user
  /// but can be overridden to mark a chore done on behalf of someone else.
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
      files.add(http.MultipartFile.fromBytes('photo_before', bytes, filename: photoBefore.name));
    }
    if (photoAfter != null) {
      final bytes = await photoAfter.readAsBytes();
      files.add(http.MultipartFile.fromBytes('photo_after', bytes, filename: photoAfter.name));
    }

    await _pb.collection(Collections.choreLogs).create(body: body, files: files);
    await _pb.collection(Collections.chores).update(choreId, body: {'onetimeonly_assignee': ''});
  }

  Future<List<AppUser>> fetchUsers() async {
    final records = await _pb.collection(Collections.users).getFullList(sort: 'name');
    return records.map(AppUser.fromRecord).toList();
  }
}