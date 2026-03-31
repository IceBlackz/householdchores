import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import '../constants/app_constants.dart';
import '../models/chore.dart';
import '../services/chore_service.dart';
import '../services/pocketbase_service.dart';

class ChoreProvider extends ChangeNotifier {
  ChoreProvider(this._choreService);

  final ChoreService _choreService;

  List<Chore> _chores = [];
  Map<String, DateTime> _dueDates = {};
  Map<String, DateTime> _maxDueDates = {};
  bool _isLoading = false;
  String? _error;
  String? _seasonFilter;

  UnsubscribeFunc? _unsubscribeChores;
  UnsubscribeFunc? _unsubscribeLogs;
  String? _currentUserId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get seasonFilter => _seasonFilter;

  List<Chore> get chores {
    if (_seasonFilter == null) return _chores;
    return _chores.where((c) => c.season == 'All' || c.season == _seasonFilter).toList();
  }

  DateTime? dueDate(String choreId) => _dueDates[choreId];
  DateTime? maxDueDate(String choreId) => _maxDueDates[choreId];

  void setSeasonFilter(String? season) {
    _seasonFilter = season;
    notifyListeners();
  }

  static String currentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Autumn';
    return 'Winter';
  }

  Future<void> initRealtime(String userId) async {
    _currentUserId = userId;
    await _cancelSubscriptions();
    final pb = PocketBaseService().client;
    _unsubscribeChores = await pb.collection(Collections.chores).subscribe('*', _onRealtimeEvent);
    _unsubscribeLogs = await pb.collection(Collections.choreLogs).subscribe('*', _onRealtimeEvent);
  }

  void _onRealtimeEvent(RecordSubscriptionEvent event) {
    if (_isLoading) return;
    final userId = _currentUserId;
    if (userId != null) refresh(userId);
  }

  Future<void> _cancelSubscriptions() async {
    await _unsubscribeChores?.call();
    await _unsubscribeLogs?.call();
    _unsubscribeChores = null;
    _unsubscribeLogs = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  Future<void> refresh(String currentUserId) async {
    _currentUserId = currentUserId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final chores = await _choreService.fetchChores();
      final Map<String, DateTime> dueDates = {};
      final Map<String, DateTime> maxDueDates = {};

      final latestLogs = await _choreService.fetchLatestLogPerChore(
        chores.map((c) => c.id).toList(),
      );

      final activeSeason = currentSeason();

      for (final chore in chores) {
        final latestLog = latestLogs[chore.id];
        if (latestLog != null) {
          dueDates[chore.id] = chore.nextDueDate(latestLog.created, activeSeason);
          maxDueDates[chore.id] = chore.maxDueDate(latestLog.created);
        } else {
          final sentinel = DateTime.now()
              .subtract(Duration(days: AppConstants.neverCompletedSentinelDays));
          dueDates[chore.id] = sentinel;
          maxDueDates[chore.id] = sentinel;
        }
      }

      chores.sort((a, b) {
        final aIsMine = a.activeAssigneeId == currentUserId;
        final bIsMine = b.activeAssigneeId == currentUserId;
        if (aIsMine && !bIsMine) return -1;
        if (!aIsMine && bIsMine) return 1;
        return dueDates[a.id]!.compareTo(dueDates[b.id]!);
      });

      _chores = chores;
      _dueDates = dueDates;
      _maxDueDates = maxDueDates;
    } catch (e) {
      _error = 'Failed to load chores: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// [completedBy] defaults to [currentUserId] but can be any user ID
  /// when marking a chore done on behalf of someone else.
  Future<void> completeChore(
    String choreId,
    String currentUserId, {
    String? completedBy,
    XFile? photoBefore,
    XFile? photoAfter,
    String notes = '',
  }) async {
    await _choreService.completeChore(
      choreId,
      completedBy: completedBy ?? currentUserId,
      photoBefore: photoBefore,
      photoAfter: photoAfter,
      notes: notes,
    );
    await refresh(currentUserId);
  }

  Future<void> deleteChore(String choreId, String currentUserId) async {
    await _choreService.deleteChore(choreId);
    await refresh(currentUserId);
  }
}