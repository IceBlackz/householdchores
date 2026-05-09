import 'package:pocketbase/pocketbase.dart';
import '../constants/app_constants.dart';
import '../models/notification_settings.dart';
import 'pocketbase_service.dart';

class SettingsService {
  PocketBase get _pb => PocketBaseService().client;

  Future<NotificationSettings> fetchNotificationSettings() async {
    try {
      final record = await _pb
          .collection(Collections.appSettings)
          .getFirstListItem('key="${NotificationSettings.settingsKey}"');
      final value = record.data['value'];
      if (value is Map<String, dynamic>) {
        return NotificationSettings.fromMap(value);
      }
    } on ClientException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
    return const NotificationSettings();
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    final body = {
      'key': NotificationSettings.settingsKey,
      'value': settings.toMap(),
    };

    try {
      final record = await _pb
          .collection(Collections.appSettings)
          .getFirstListItem('key="${NotificationSettings.settingsKey}"');
      await _pb
          .collection(Collections.appSettings)
          .update(record.id, body: body);
    } on ClientException catch (e) {
      if (e.statusCode != 404) rethrow;
      await _pb.collection(Collections.appSettings).create(body: body);
    }
  }
}
