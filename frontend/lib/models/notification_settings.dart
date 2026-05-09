class NotificationSettings {
  const NotificationSettings({
    this.mobileNotificationsEnabled = false,
    this.notifyOnlyMine = true,
    this.includeDueToday = true,
    this.includeOverdue = true,
    this.includeCritical = true,
    this.actionButtonsEnabled = true,
    this.quietHoursEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.reminderTime = '08:00',
    this.escalationDays = 2,
    this.homeAssistantDueRemindersEnabled = false,
    this.homeAssistantWebhookUrl = '',
    this.serverPushEnabled = false,
  });

  static const settingsKey = 'notification_settings';

  final bool mobileNotificationsEnabled;
  final bool notifyOnlyMine;
  final bool includeDueToday;
  final bool includeOverdue;
  final bool includeCritical;
  final bool actionButtonsEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String reminderTime;
  final int escalationDays;
  final bool homeAssistantDueRemindersEnabled;
  final String homeAssistantWebhookUrl;
  final bool serverPushEnabled;

  NotificationSettings copyWith({
    bool? mobileNotificationsEnabled,
    bool? notifyOnlyMine,
    bool? includeDueToday,
    bool? includeOverdue,
    bool? includeCritical,
    bool? actionButtonsEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? reminderTime,
    int? escalationDays,
    bool? homeAssistantDueRemindersEnabled,
    String? homeAssistantWebhookUrl,
    bool? serverPushEnabled,
  }) {
    return NotificationSettings(
      mobileNotificationsEnabled:
          mobileNotificationsEnabled ?? this.mobileNotificationsEnabled,
      notifyOnlyMine: notifyOnlyMine ?? this.notifyOnlyMine,
      includeDueToday: includeDueToday ?? this.includeDueToday,
      includeOverdue: includeOverdue ?? this.includeOverdue,
      includeCritical: includeCritical ?? this.includeCritical,
      actionButtonsEnabled: actionButtonsEnabled ?? this.actionButtonsEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      reminderTime: reminderTime ?? this.reminderTime,
      escalationDays: escalationDays ?? this.escalationDays,
      homeAssistantDueRemindersEnabled:
          homeAssistantDueRemindersEnabled ??
          this.homeAssistantDueRemindersEnabled,
      homeAssistantWebhookUrl:
          homeAssistantWebhookUrl ?? this.homeAssistantWebhookUrl,
      serverPushEnabled: serverPushEnabled ?? this.serverPushEnabled,
    );
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      mobileNotificationsEnabled:
          map['mobileNotificationsEnabled'] as bool? ?? false,
      notifyOnlyMine: map['notifyOnlyMine'] as bool? ?? true,
      includeDueToday: map['includeDueToday'] as bool? ?? true,
      includeOverdue: map['includeOverdue'] as bool? ?? true,
      includeCritical: map['includeCritical'] as bool? ?? true,
      actionButtonsEnabled: map['actionButtonsEnabled'] as bool? ?? true,
      quietHoursEnabled: map['quietHoursEnabled'] as bool? ?? true,
      quietHoursStart: map['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: map['quietHoursEnd'] as String? ?? '07:00',
      reminderTime: map['reminderTime'] as String? ?? '08:00',
      escalationDays: map['escalationDays'] as int? ?? 2,
      homeAssistantDueRemindersEnabled:
          map['homeAssistantDueRemindersEnabled'] as bool? ?? false,
      homeAssistantWebhookUrl: map['homeAssistantWebhookUrl'] as String? ?? '',
      serverPushEnabled: map['serverPushEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mobileNotificationsEnabled': mobileNotificationsEnabled,
      'notifyOnlyMine': notifyOnlyMine,
      'includeDueToday': includeDueToday,
      'includeOverdue': includeOverdue,
      'includeCritical': includeCritical,
      'actionButtonsEnabled': actionButtonsEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'reminderTime': reminderTime,
      'escalationDays': escalationDays,
      'homeAssistantDueRemindersEnabled': homeAssistantDueRemindersEnabled,
      'homeAssistantWebhookUrl': homeAssistantWebhookUrl,
      'serverPushEnabled': serverPushEnabled,
    };
  }
}
