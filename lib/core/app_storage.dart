import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class AppStorage {
  AppStorage({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _stateKey = 'campusx.state.v1';

  final SharedPreferencesAsync _preferences;

  Future<CampusState> loadState() async {
    try {
      final raw = await _preferences.getString(_stateKey);
      if (raw == null || raw.isEmpty) return CampusState.initial();
      return CampusState.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return CampusState.initial();
    }
  }

  Future<void> saveState(CampusState state) async {
    await _preferences.setString(_stateKey, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    await _preferences.remove(_stateKey);
  }
}
