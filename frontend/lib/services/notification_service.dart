import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/chore.dart';
import '../models/notification_settings.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.rememberPendingAction(
    response.actionId,
    response.payload,
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'householdchores_due';
  static const _channelName = 'Due chores';
  static const _completeActionId = 'complete';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _completeActions =
      StreamController<String>.broadcast();

  bool _initialized = false;
  static String? _pendingPayload;
  static String? _pendingActionId;

  Stream<String> get completeActions => _completeActions.stream;

  bool get _supportsLocalNotifications {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static void rememberPendingAction(String? actionId, String? payload) {
    _pendingActionId = actionId;
    _pendingPayload = payload;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (!_supportsLocalNotifications) {
      _initialized = true;
      return;
    }

    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          'chore_actions',
          actions: [
            DarwinNotificationAction.plain(_completeActionId, 'Complete'),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  String? takePendingCompleteAction() {
    if (_pendingActionId != _completeActionId || _pendingPayload == null) {
      return null;
    }
    final payload = _pendingPayload;
    _pendingActionId = null;
    _pendingPayload = null;
    return _choreIdFromPayload(payload);
  }

  Future<void> scheduleDueReminders({
    required List<Chore> chores,
    required Map<String, DateTime> dueDates,
    required Map<String, DateTime> maxDueDates,
    required String currentUserId,
    required NotificationSettings settings,
  }) async {
    if (!_supportsLocalNotifications) return;

    await initialize();
    await _plugin.cancelAll();
    if (!settings.mobileNotificationsEnabled) return;

    for (final chore in chores) {
      if (settings.notifyOnlyMine && chore.activeAssigneeId != currentUserId) {
        continue;
      }

      final dueDate = dueDates[chore.id];
      if (dueDate == null) continue;

      final maxDueDate = maxDueDates[chore.id];
      final status = _statusFor(dueDate, maxDueDate, settings.escalationDays);
      if (!_statusAllowed(status, settings)) continue;

      final scheduledAt = _nextReminderDate(settings);
      await _plugin.zonedSchedule(
        id: _notificationId(chore.id),
        title: _titleFor(status, chore.title),
        body: _bodyFor(status, chore.activeAssigneeName),
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Reminders for chores that need attention.',
            importance: Importance.high,
            priority: Priority.high,
            actions: settings.actionButtonsEnabled
                ? const [
                    AndroidNotificationAction(
                      _completeActionId,
                      'Complete',
                      showsUserInterface: true,
                    ),
                  ]
                : null,
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: settings.actionButtonsEnabled
                ? 'chore_actions'
                : null,
          ),
          macOS: DarwinNotificationDetails(
            categoryIdentifier: settings.actionButtonsEnabled
                ? 'chore_actions'
                : null,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'chore:${chore.id}',
      );
    }
  }

  void _handleResponse(NotificationResponse response) {
    if (response.actionId == _completeActionId) {
      final choreId = _choreIdFromPayload(response.payload);
      if (choreId != null) {
        _completeActions.add(choreId);
      }
    }
  }

  static String? _choreIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith('chore:')) return null;
    return payload.substring('chore:'.length);
  }

  static int _notificationId(String choreId) {
    return choreId.codeUnits.fold<int>(17, (value, unit) {
      return (value * 31 + unit) & 0x7fffffff;
    });
  }

  static DateTime _nextReminderDate(NotificationSettings settings) {
    final now = DateTime.now();
    final parts = settings.reminderTime.split(':');
    final hour = int.tryParse(parts.first) ?? 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return _moveOutOfQuietHours(scheduled, settings);
  }

  static DateTime _timeOnDate(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static DateTime _moveOutOfQuietHours(
    DateTime scheduled,
    NotificationSettings settings,
  ) {
    if (!settings.quietHoursEnabled) return scheduled;

    final start = _timeOnDate(scheduled, settings.quietHoursStart);
    final end = _timeOnDate(scheduled, settings.quietHoursEnd);
    final spansMidnight = !end.isAfter(start);

    if (spansMidnight) {
      if (!scheduled.isBefore(start)) {
        return end.add(const Duration(days: 1));
      }
      if (scheduled.isBefore(end)) return end;
      return scheduled;
    }

    if (!scheduled.isBefore(start) && scheduled.isBefore(end)) {
      return end;
    }
    return scheduled;
  }

  static _ReminderStatus _statusFor(
    DateTime dueDate,
    DateTime? maxDueDate,
    int escalationDays,
  ) {
    if (dueDate.year < 2000) return _ReminderStatus.neverCompleted;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final maxDay = maxDueDate == null
        ? null
        : DateTime(maxDueDate.year, maxDueDate.month, maxDueDate.day);

    if (maxDay != null && maxDay.isBefore(today)) {
      return _ReminderStatus.critical;
    }
    if (dueDay.isBefore(today)) {
      final daysOverdue = today.difference(dueDay).inDays;
      if (daysOverdue >= escalationDays) return _ReminderStatus.critical;
      return _ReminderStatus.overdue;
    }
    if (dueDay.isAtSameMomentAs(today)) return _ReminderStatus.dueToday;
    return _ReminderStatus.notDue;
  }

  static bool _statusAllowed(
    _ReminderStatus status,
    NotificationSettings settings,
  ) {
    return switch (status) {
      _ReminderStatus.neverCompleted => settings.includeOverdue,
      _ReminderStatus.overdue => settings.includeOverdue,
      _ReminderStatus.dueToday => settings.includeDueToday,
      _ReminderStatus.critical => settings.includeCritical,
      _ReminderStatus.notDue => false,
    };
  }

  static String _titleFor(_ReminderStatus status, String choreTitle) {
    return switch (status) {
      _ReminderStatus.critical => 'Critical chore: $choreTitle',
      _ReminderStatus.neverCompleted => 'Chore not started: $choreTitle',
      _ReminderStatus.overdue => 'Overdue chore: $choreTitle',
      _ReminderStatus.dueToday => 'Chore due today: $choreTitle',
      _ReminderStatus.notDue => choreTitle,
    };
  }

  static String _bodyFor(_ReminderStatus status, String assigneeName) {
    final assignee = assigneeName.isEmpty ? 'Anyone' : assigneeName;
    return switch (status) {
      _ReminderStatus.critical => '$assignee is past the hard deadline.',
      _ReminderStatus.neverCompleted => '$assignee can complete the first log.',
      _ReminderStatus.overdue => '$assignee has a chore waiting.',
      _ReminderStatus.dueToday => '$assignee has a chore due today.',
      _ReminderStatus.notDue => '',
    };
  }
}

enum _ReminderStatus { notDue, dueToday, overdue, critical, neverCompleted }
