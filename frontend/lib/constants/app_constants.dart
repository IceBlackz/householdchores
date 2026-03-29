class AppConstants {
  // Sentinel: chores never completed are sorted as if overdue by this many days.
  // Must be large enough that year < 2000 check identifies them on the dashboard.
  static const int neverCompletedSentinelDays = 9999;

  // Chore form field defaults
  static const int defaultDesiredIntervalDays = 7;
  static const int defaultMaxIntervalDays = 14;

  // Display labels
  static const String unassignedLabel = 'Unassigned';

  // Season values — single source of truth shared by UI and schema
  static const List<String> seasons = [
    'All',
    'Spring',
    'Summer',
    'Autumn',
    'Winter',
  ];
}

/// PocketBase collection names.
class Collections {
  static const String users = 'users';
  static const String chores = 'chores';
  static const String choreLogs = 'chore_logs';
}

/// Allowed values for the chore interval_unit field.
class IntervalUnits {
  static const String days = 'days';
  static const String weeks = 'weeks';
  static const String months = 'months';
  static const String quarters = 'quarters';
  static const String years = 'years';

  static const List<String> all = [days, weeks, months, quarters, years];

  static String label(String unit) {
    switch (unit) {
      case weeks:    return 'Weeks';
      case months:   return 'Months';
      case quarters: return 'Quarters';
      case years:    return 'Years';
      default:       return 'Days';
    }
  }
}
