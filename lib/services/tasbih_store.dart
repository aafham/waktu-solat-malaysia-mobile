import 'package:shared_preferences/shared_preferences.dart';

class TasbihStore {
  static const _tasbihCountKey = 'tasbih_count';
  static const _notifyEnabledKey = 'notify_enabled';
  static const _vibrateEnabledKey = 'vibrate_enabled';
  static const _autoLocationKey = 'auto_location';
  static const _manualZoneKey = 'manual_zone';

  Future<int> loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tasbihCountKey) ?? 0;
  }

  Future<void> saveCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tasbihCountKey, value);
  }

  Future<bool> loadNotifyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifyEnabledKey) ?? true;
  }

  Future<void> saveNotifyEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifyEnabledKey, value);
  }

  Future<bool> loadVibrateEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrateEnabledKey) ?? true;
  }

  Future<void> saveVibrateEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrateEnabledKey, value);
  }

  Future<bool> loadAutoLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoLocationKey) ?? true;
  }

  Future<void> saveAutoLocation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLocationKey, value);
  }

  Future<String> loadManualZone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_manualZoneKey) ?? 'SGR01';
  }

  Future<void> saveManualZone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_manualZoneKey, value);
  }
}
