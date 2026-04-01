import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/house.dart';

/// Provider for managing multiple PocketBase server configurations (houses).
/// Handles adding, editing, deleting houses and switching between them.
class HouseProvider extends ChangeNotifier {
  final List<House> _houses = [];
  String? _activeHouseId;

  /// Default local house URL.
  /// On web this returns the same host as the page on port 9010,
  /// so the app served from :9011 automatically talks to :9010
  /// without any manual configuration.
  /// On native it falls back to the BACKEND_URL dart-define or localhost.
  static String get defaultLocalHouseUrl => AppConfig.backendUrl;

  static const String defaultLocalHouseName = 'Local';

  HouseProvider() {
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    final prefs = await SharedPreferences.getInstance();
    final housesJson = prefs.getStringList('houses') ?? [];

    _houses.clear();
    for (final json in housesJson) {
      final house = House.fromMap(jsonDecode(json));
      _houses.add(house);
    }

    if (_activeHouseId == null || _activeHouseId == '') {
      if (_houses.isEmpty) {
        final defaultHouse = House(
          id: 'default',
          name: defaultLocalHouseName,
          url: defaultLocalHouseUrl,
        );
        _houses.add(defaultHouse);
        _activeHouseId = defaultHouse.id;
      } else if (!_houses.any((h) => h.id == _activeHouseId)) {
        _activeHouseId = _houses.first.id;
      }
    }

    notifyListeners();
  }

  Future<void> _saveHouses() async {
    final prefs = await SharedPreferences.getInstance();
    final housesJson = _houses.map((h) => jsonEncode(h.toMap())).toList();
    await prefs.setStringList('houses', housesJson);
  }

  List<House> get houses => List.unmodifiable(_houses);

  House? get activeHouse {
    if (_activeHouseId == null) return null;
    return _houses.firstWhere(
      (h) => h.id == _activeHouseId,
      orElse: () => _houses.first,
    );
  }

  String? get activeHouseId => _activeHouseId;
  bool get hasActiveHouse => _activeHouseId != null && _activeHouseId != '';

  /// Adds a new house and returns its generated ID so the caller
  /// can immediately switchHouse(newId).
  Future<String> addHouse({
    required String name,
    required String url,
    String? haWebhookUrl,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) {
      throw ArgumentError('Invalid URL: $url');
    }
    if (_houses.any((h) => h.url == url)) {
      throw ArgumentError('A house with URL $url already exists');
    }

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newHouse = House(
      id: newId,
      name: name,
      url: url,
      haWebhookUrl: haWebhookUrl,
    );

    _houses.add(newHouse);
    await _saveHouses();
    notifyListeners();
    return newId;
  }

  Future<void> editHouse(String houseId, {
    String? name,
    String? url,
    String? haWebhookUrl,
  }) async {
    final houseIndex = _houses.indexWhere((h) => h.id == houseId);
    if (houseIndex == -1) throw ArgumentError('House not found: $houseId');

    final house = _houses[houseIndex];

    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.isAbsolute) {
        throw ArgumentError('Invalid URL: $url');
      }
      if (url != house.url &&
          _houses.any((h) => h.url == url && h.id != houseId)) {
        throw ArgumentError('A house with URL $url already exists');
      }
    }

    _houses[houseIndex] = House(
      id: house.id,
      name: name ?? house.name,
      url: url ?? house.url,
      haWebhookUrl: haWebhookUrl ?? house.haWebhookUrl,
    );
    await _saveHouses();
    notifyListeners();
  }

  Future<void> deleteHouse(String houseId) async {
    if (_houses.length == 1) {
      throw ArgumentError('Cannot delete the last house');
    }

    final houseIndex = _houses.indexWhere((h) => h.id == houseId);
    if (houseIndex == -1) throw ArgumentError('House not found: $houseId');

    _houses.removeAt(houseIndex);
    await _saveHouses();

    if (houseId == _activeHouseId && _houses.isNotEmpty) {
      _activeHouseId = _houses.first.id;
    }

    notifyListeners();
  }

  Future<void> switchHouse(String houseId) async {
    if (!_houses.any((h) => h.id == houseId)) {
      throw ArgumentError('House not found: $houseId');
    }
    _activeHouseId = houseId;
    await _saveHouses();
    notifyListeners();
  }

  Future<void> switchToLocalHouse() async {
    final defaultHouse = House(
      id: 'default',
      name: defaultLocalHouseName,
      url: defaultLocalHouseUrl,
    );
    if (!_houses.any((h) => h.url == defaultLocalHouseUrl)) {
      _houses.add(defaultHouse);
    }
    _activeHouseId = defaultHouse.id;
    await _saveHouses();
    notifyListeners();
  }

  String get activeHouseUrl => activeHouse?.url ?? defaultLocalHouseUrl;
  String get activeHouseName => activeHouse?.name ?? defaultLocalHouseName;
  bool isDefaultHouse(House house) => house.url == defaultLocalHouseUrl;

  /// Public method to trigger a UI rebuild without mutating any data.
  void refresh() => notifyListeners();

  Future<void> clearAllHouses() async {
    _houses.clear();
    _activeHouseId = null;
    await _saveHouses();
    notifyListeners();
  }
}