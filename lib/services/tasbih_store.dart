import 'package:shared_preferences/shared_preferences.dart';

class TasbihStore {
  static const _tasbihCountKey = 'tasbih_count';
  static const _notifyEnabledKey = 'notify_enabled';
  static const _vibrateEnabledKey = 'vibrate_enabled';
  static const _autoLocationKey = 'auto_location';
  static const _manualZoneKey = 'manual_zone';
  static const _favoriteZonesKey = 'favorite_zones';
  static const _recentZonesKey = 'recent_zones';
  static const _prayerTogglePrefix = 'notify_prayer_';
  static const _textScaleKey = 'text_scale';
  static const _highContrastKey = 'high_contrast';

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

  Future<List<String>> loadFavoriteZones() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoriteZonesKey) ?? <String>[];
  }

  Future<void> saveFavoriteZones(List<String> zones) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteZonesKey, zones);
  }

  Future<List<String>> loadRecentZones() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentZonesKey) ?? <String>[];
  }

  Future<void> saveRecentZones(List<String> zones) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentZonesKey, zones);
  }

  Future<Map<String, bool>> loadPrayerNotificationToggles() async {
    final prefs = await SharedPreferences.getInstance();
    return <String, bool>{
      'Imsak': prefs.getBool('${_prayerTogglePrefix}Imsak') ?? true,
      'Subuh': prefs.getBool('${_prayerTogglePrefix}Subuh') ?? true,
      'Syuruk': prefs.getBool('${_prayerTogglePrefix}Syuruk') ?? false,
      'Zohor': prefs.getBool('${_prayerTogglePrefix}Zohor') ?? true,
      'Asar': prefs.getBool('${_prayerTogglePrefix}Asar') ?? true,
      'Maghrib': prefs.getBool('${_prayerTogglePrefix}Maghrib') ?? true,
      'Isyak': prefs.getBool('${_prayerTogglePrefix}Isyak') ?? true,
    };
  }

  Future<void> savePrayerNotificationToggle(String prayerName, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prayerTogglePrefix$prayerName', value);
  }

  Future<double> loadTextScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_textScaleKey) ?? 1.0;
  }

  Future<void> saveTextScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, value);
  }

  Future<bool> loadHighContrast() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_highContrastKey) ?? false;
  }

  Future<void> saveHighContrast(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
  }
}
