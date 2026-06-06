import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('uses system theme by default', () async {
      final provider = ThemeProvider();
      await provider.load();

      expect(provider.themeMode, ThemeMode.system);
      expect(provider.followsSystem, isTrue);
    });

    test('persists dark mode override', () async {
      final provider = ThemeProvider();
      await provider.load();

      await provider.setDarkMode(true);

      final nextProvider = ThemeProvider();
      await nextProvider.load();

      expect(nextProvider.themeMode, ThemeMode.dark);
      expect(nextProvider.followsSystem, isFalse);
    });

    test('can return to system theme', () async {
      final provider = ThemeProvider();
      await provider.load();
      await provider.setDarkMode(false);

      await provider.useSystemTheme();

      final nextProvider = ThemeProvider();
      await nextProvider.load();

      expect(nextProvider.themeMode, ThemeMode.system);
      expect(nextProvider.followsSystem, isTrue);
    });
  });
}
