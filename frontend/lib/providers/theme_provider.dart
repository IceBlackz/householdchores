import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  static const _system = 'system';
  static const _light = 'light';
  static const _dark = 'dark';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get followsSystem => _themeMode == ThemeMode.system;

  bool isDarkMode(BuildContext context) {
    return switch (_themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _modeFromString(prefs.getString(_key));
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    await _setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> useSystemTheme() async {
    await _setThemeMode(ThemeMode.system);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _modeToString(mode));
  }

  ThemeMode _modeFromString(String? value) {
    return switch (value) {
      _light => ThemeMode.light,
      _dark => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  String _modeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => _light,
      ThemeMode.dark => _dark,
      ThemeMode.system => _system,
    };
  }
}
