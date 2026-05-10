class DashboardPreferences {
  const DashboardPreferences({
    this.defaultFilter = defaultFilterAll,
    this.quickCompleteEnabled = true,
    this.celebrationsEnabled = true,
  });

  static const defaultFilterAll = 'all';
  static const defaultFilterMine = 'mine';
  static const defaultFilterAttention = 'attention';
  static const defaultFilterCritical = 'critical';

  static const defaultFilters = [
    defaultFilterAll,
    defaultFilterMine,
    defaultFilterAttention,
    defaultFilterCritical,
  ];

  final String defaultFilter;
  final bool quickCompleteEnabled;
  final bool celebrationsEnabled;

  DashboardPreferences copyWith({
    String? defaultFilter,
    bool? quickCompleteEnabled,
    bool? celebrationsEnabled,
  }) {
    return DashboardPreferences(
      defaultFilter: defaultFilters.contains(defaultFilter)
          ? defaultFilter!
          : this.defaultFilter,
      quickCompleteEnabled: quickCompleteEnabled ?? this.quickCompleteEnabled,
      celebrationsEnabled: celebrationsEnabled ?? this.celebrationsEnabled,
    );
  }
}
