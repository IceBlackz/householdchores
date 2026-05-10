import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/dashboard_preferences.dart';
import 'package:frontend/services/dashboard_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DashboardPreferencesService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads defaults when no preferences are stored', () async {
      final preferences = await DashboardPreferencesService().load();

      expect(preferences.defaultFilter, DashboardPreferences.defaultFilterAll);
      expect(preferences.quickCompleteEnabled, isTrue);
      expect(preferences.celebrationsEnabled, isTrue);
    });

    test('persists dashboard preferences', () async {
      final service = DashboardPreferencesService();
      await service.save(
        const DashboardPreferences(
          defaultFilter: DashboardPreferences.defaultFilterAttention,
          quickCompleteEnabled: false,
          celebrationsEnabled: false,
        ),
      );

      final preferences = await service.load();

      expect(
        preferences.defaultFilter,
        DashboardPreferences.defaultFilterAttention,
      );
      expect(preferences.quickCompleteEnabled, isFalse);
      expect(preferences.celebrationsEnabled, isFalse);
    });

    test('falls back to all chores for unknown stored filters', () async {
      SharedPreferences.setMockInitialValues({
        'dashboard.defaultFilter': 'kitchen-zone',
      });

      final preferences = await DashboardPreferencesService().load();

      expect(preferences.defaultFilter, DashboardPreferences.defaultFilterAll);
    });
  });
}
