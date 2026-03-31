import 'package:pocketbase/pocketbase.dart';
import 'app_user.dart';
import '../constants/app_constants.dart';

class Chore {
  const Chore({
    required this.id,
    required this.title,
    required this.description,
    required this.intervalDesiredDays,
    required this.intervalMaxDays,
    required this.intervalUnit,
    required this.season,
    required this.created,
    this.seasonSpringOverride,
    this.seasonSummerOverride,
    this.seasonAutumnOverride,
    this.seasonWinterOverride,
    this.defaultAssignee,
    this.onetimeOnlyAssignee,
  });

  final String id;
  final String title;
  final String description;
  final int intervalDesiredDays;
  final int intervalMaxDays;
  final String intervalUnit;
  final String season;
  final DateTime created;

  final int? seasonSpringOverride;
  final int? seasonSummerOverride;
  final int? seasonAutumnOverride;
  final int? seasonWinterOverride;

  final AppUser? defaultAssignee;
  final AppUser? onetimeOnlyAssignee;

  bool get hasOneTimeOverride => onetimeOnlyAssignee != null;
  AppUser? get activeAssignee => onetimeOnlyAssignee ?? defaultAssignee;
  String get activeAssigneeName =>
      activeAssignee?.displayName ?? AppConstants.unassignedLabel;
  String get activeAssigneeId => activeAssignee?.id ?? '';

  int? seasonOverride(String season) {
    int? v;
    switch (season) {
      case 'Spring': v = seasonSpringOverride; break;
      case 'Summer': v = seasonSummerOverride; break;
      case 'Autumn': v = seasonAutumnOverride; break;
      case 'Winter': v = seasonWinterOverride; break;
    }
    return (v != null && v > 0) ? v : null;
  }

  /// Desired due date — uses season overrides and interval unit.
  DateTime nextDueDate(DateTime lastCompleted, String activeSeason) {
    final override = seasonOverride(activeSeason);
    final value = override ?? intervalDesiredDays;
    return _addInterval(lastCompleted, value, intervalUnit);
  }

  /// Hard deadline — uses intervalMaxDays with no season overrides.
  DateTime maxDueDate(DateTime lastCompleted) {
    return _addInterval(lastCompleted, intervalMaxDays, intervalUnit);
  }

  static DateTime _addInterval(DateTime base, int value, String unit) {
    switch (unit) {
      case IntervalUnits.weeks:
        return base.add(Duration(days: value * 7));
      case IntervalUnits.months:
        return DateTime(base.year, base.month + value, base.day);
      case IntervalUnits.quarters:
        return DateTime(base.year, base.month + value * 3, base.day);
      case IntervalUnits.years:
        return DateTime(base.year + value, base.month, base.day);
      default:
        return base.add(Duration(days: value));
    }
  }

  factory Chore.fromRecord(RecordModel record) {
    AppUser? defaultAssignee;
    AppUser? onetimeOnlyAssignee;

    try {
      final def = record.get<RecordModel?>('expand.default_assignee');
      if (def != null) defaultAssignee = AppUser.fromRecord(def);
    } catch (_) {}

    try {
      final oto = record.get<RecordModel?>('expand.onetimeonly_assignee');
      if (oto != null) onetimeOnlyAssignee = AppUser.fromRecord(oto);
    } catch (_) {}

    final createdStr = record.getStringValue('created');
    final created = createdStr.isNotEmpty
        ? DateTime.parse(createdStr)
        : DateTime.now();

    int? nullIfZero(int v) => v > 0 ? v : null;

    return Chore(
      id: record.id,
      title: record.getStringValue('title'),
      description: record.getStringValue('description'),
      intervalDesiredDays: record.getIntValue('interval_desired_days'),
      intervalMaxDays: record.getIntValue('interval_max_days'),
      intervalUnit: record.getStringValue('interval_unit').isNotEmpty
          ? record.getStringValue('interval_unit')
          : IntervalUnits.days,
      season: record.getStringValue('season'),
      created: created,
      seasonSpringOverride: nullIfZero(record.getIntValue('season_spring_override')),
      seasonSummerOverride: nullIfZero(record.getIntValue('season_summer_override')),
      seasonAutumnOverride: nullIfZero(record.getIntValue('season_autumn_override')),
      seasonWinterOverride: nullIfZero(record.getIntValue('season_winter_override')),
      defaultAssignee: defaultAssignee,
      onetimeOnlyAssignee: onetimeOnlyAssignee,
    );
  }
}