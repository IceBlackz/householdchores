import 'package:pocketbase/pocketbase.dart';
import 'app_user.dart';

class ChoreLog {
  const ChoreLog({
    required this.id,
    required this.choreId,
    required this.completedById,
    required this.notes,
    required this.created,
    this.completedByName,
    this.photoBeforeFilename,
    this.photoAfterFilename,
    this.collectionId,
  });

  final String id;
  final String choreId;
  final String completedById;
  final String notes;
  final DateTime created;

  final String? completedByName;
  final String? photoBeforeFilename;
  final String? photoAfterFilename;
  final String? collectionId;

  factory ChoreLog.fromRecord(RecordModel record) {
    String? completedByName;
    try {
      final user = record.get<RecordModel?>('expand.completed_by');
      if (user != null) completedByName = AppUser.fromRecord(user).displayName;
    } catch (_) {}

    // PocketBase returns file fields as List<dynamic> even for maxSelect: 1
    String? photoBefore;
    String? photoAfter;
    final beforeList = record.data['photo_before'];
    if (beforeList is List && beforeList.isNotEmpty) {
      photoBefore = beforeList.first as String?;
    } else if (beforeList is String && beforeList.isNotEmpty) {
      photoBefore = beforeList;
    }
    final afterList = record.data['photo_after'];
    if (afterList is List && afterList.isNotEmpty) {
      photoAfter = afterList.first as String?;
    } else if (afterList is String && afterList.isNotEmpty) {
      photoAfter = afterList;
    }

    return ChoreLog(
      id: record.id,
      choreId: record.getStringValue('chore'),
      completedById: record.getStringValue('completed_by'),
      notes: record.getStringValue('notes'),
      created: DateTime.parse(record.getStringValue('created')),
      completedByName: completedByName,
      photoBeforeFilename: photoBefore,
      photoAfterFilename: photoAfter,
      collectionId: record.collectionId,
    );
  }
}
