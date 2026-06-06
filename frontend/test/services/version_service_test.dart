import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/version_service.dart';

void main() {
  group('VersionService.versionUriFor', () {
    test('builds version endpoint for a plain local server URL', () {
      final uri = VersionService.versionUriFor('http://192.168.1.20:9010');

      expect(
        uri.toString(),
        'http://192.168.1.20:9010/api/householdchores/version',
      );
    });

    test('does not create double slashes when base URL has trailing slash', () {
      final uri = VersionService.versionUriFor('http://192.168.1.20:9010/');

      expect(
        uri.toString(),
        'http://192.168.1.20:9010/api/householdchores/version',
      );
    });

    test('preserves reverse proxy base path', () {
      final uri = VersionService.versionUriFor(
        'https://chores.example.com/pocketbase/',
      );

      expect(
        uri.toString(),
        'https://chores.example.com/pocketbase/api/householdchores/version',
      );
    });
  });
}
