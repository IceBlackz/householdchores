import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_preferences.dart';

class DashboardPreferencesService {
  static const _defaultFilterKey = 'dashboard.defaultFilter';
  static const _quickCompleteKey = 'dashboard.quickCompleteEnabled';
  static const _celebrationsKey = 'dashboard.celebrationsEnabled';

  Future<DashboardPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultFilter =
        prefs.getString(_defaultFilterKey) ??
        DashboardPreferences.defaultFilterAll;

    return DashboardPreferences(
      defaultFilter: DashboardPreferences.defaultFilters.contains(defaultFilter)
          ? defaultFilter
          : DashboardPreferences.defaultFilterAll,
      quickCompleteEnabled: prefs.getBool(_quickCompleteKey) ?? true,
      celebrationsEnabled: prefs.getBool(_celebrationsKey) ?? true,
    );
  }

  Future<void> save(DashboardPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultFilterKey, preferences.defaultFilter);
    await prefs.setBool(_quickCompleteKey, preferences.quickCompleteEnabled);
    await prefs.setBool(_celebrationsKey, preferences.celebrationsEnabled);
  }
}
