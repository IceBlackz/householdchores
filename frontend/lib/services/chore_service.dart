import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/chore.dart';
import '../models/chore_log.dart';
import 'pocketbase_service.dart';

class ChoreService {
  ChoreService() : _pb = PocketBaseService().client;

  final PocketBase _pb;

  // ---------------------------------------------------------------------------
  // Chores
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Chore Logs
  // ---------------------------------------------------------------------------

  /// Returns the most recent log per chore for all [choreIds] in a single query.
  /// This avoids an N+1 pattern on the dashboard — one HTTP request instead of one per chore.
  Future<Map<String, ChoreLog>> fetchLatestLogPerChore(List<String> choreIds) async {
    if (choreIds.isEmpty) return {};

    final filter = choreIds.map((id) => 'chore="$id"').join('||');
    final records = await _pb.collection(Collections.choreLogs).getFullList(
      filter: filter,
      sort: '-created',
    );

    // Records are sorted newest-first; putIfAbsent keeps only the first (latest) per chore.
    final Map<String, ChoreLog> result = {};
    for (final record in records) {
      final choreId = record.getStringValue('chore');
      result.putIfAbsent(choreId, () => ChoreLog.fromRecord(record));
    }
    return result;
  }

  /// Returns all logs for [choreId] for the history screen, newest first.
  Future<List<ChoreLog>> fetchLogs(String choreId) async {
    final records = await _pb.collection(Collections.choreLogs).getFullList(
      filter: 'chore="$choreId"',
      sort: '-created',
      expand: 'completed_by',
    );
    return records.map(ChoreLog.fromRecord).toList();
  }

  /// Creates a completion log and atomically clears any one-time assignee override.
  Future<void> completeChore(
    String choreId, {
    XFile? photoBefore,
    XFile? photoAfter,
    String notes = '',
  }) async {
    final body = <String, dynamic>{
      'chore': choreId,
      'completed_by': _pb.authStore.record?.id,
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

    // Clear one-time override so next cycle reverts to the default assignee
    await _pb.collection(Collections.chores).update(choreId, body: {'onetimeonly_assignee': ''});
  }

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  Future<List<AppUser>> fetchUsers() async {
    final records = await _pb.collection(Collections.users).getFullList(sort: 'name');
    return records.map(AppUser.fromRecord).toList();
  }
}
