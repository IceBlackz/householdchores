import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/app_config.dart';

void main() {
  group('AppConfig.webBackendUrlFor', () {
    test('uses explicit runtime config when provided', () {
      final url = AppConfig.webBackendUrlFor(
        Uri.parse('https://chores.example.com/'),
        configuredUrl: 'https://api.example.com///',
      );

      expect(url, 'https://api.example.com');
    });

    test('maps local web port 9011 to backend port 9010', () {
      final url = AppConfig.webBackendUrlFor(
        Uri.parse('http://localhost:9011/'),
      );

      expect(url, 'http://localhost:9010');
    });

    test('uses same origin for normal HTTPS reverse proxy installs', () {
      final url = AppConfig.webBackendUrlFor(
        Uri.parse('https://chores.example.com/'),
      );

      expect(url, 'https://chores.example.com');
    });

    test('preserves non-standard reverse proxy ports', () {
      final url = AppConfig.webBackendUrlFor(
        Uri.parse('https://chores.example.com:9443/'),
      );

      expect(url, 'https://chores.example.com:9443');
    });
  });
}
