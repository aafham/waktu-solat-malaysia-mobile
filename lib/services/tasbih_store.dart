import 'dart:convert';

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
  static const _ramadhanModeKey = 'ramadhan_mode';
  static const _prayerSoundPrefix = 'prayer_sound_';
  static const _onboardingSeenKey = 'onboarding_seen';
  static const _travelModeKey = 'travel_mode_enabled';
  static const _fastingMonThuKey = 'fasting_mon_thu_enabled';
  static const _fastingAyyamulBidhKey = 'fasting_ayyamul_bidh_enabled';
  static const _tasbihDailyStatsKey = 'tasbih_daily_stats_json';
  static const _prayerCheckinsKey = 'prayer_checkins_json';

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

  Future<bool> loadRamadhanMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ramadhanModeKey) ?? false;
  }

  Future<void> saveRamadhanMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ramadhanModeKey, value);
  }

  Future<Map<String, String>> loadPrayerSoundProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final names = <String>[
      'Imsak',
      'Subuh',
      'Syuruk',
      'Zohor',
      'Asar',
      'Maghrib',
      'Isyak',
    ];
    final result = <String, String>{};
    for (final name in names) {
      result[name] = prefs.getString('$_prayerSoundPrefix$name') ?? 'default';
    }
    return result;
  }

  Future<void> savePrayerSoundProfile(String prayerName, String profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prayerSoundPrefix$prayerName', profile);
  }

  Future<bool> loadOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  Future<void> saveOnboardingSeen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, value);
  }

  Future<bool> loadTravelModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_travelModeKey) ?? true;
  }

  Future<void> saveTravelModeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_travelModeKey, value);
  }

  Future<bool> loadFastingMonThuEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fastingMonThuKey) ?? false;
  }

  Future<void> saveFastingMonThuEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fastingMonThuKey, value);
  }

  Future<bool> loadFastingAyyamulBidhEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fastingAyyamulBidhKey) ?? false;
  }

  Future<void> saveFastingAyyamulBidhEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fastingAyyamulBidhKey, value);
  }

  Future<Map<String, int>> loadTasbihDailyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasbihDailyStatsKey);
    if (raw == null || raw.isEmpty) {
      return <String, int>{};
    }
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) {
        return <String, int>{};
      }
      return parsed.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> saveTasbihDailyStats(Map<String, int> stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tasbihDailyStatsKey, jsonEncode(stats));
  }

  Future<Map<String, List<String>>> loadPrayerCheckins() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prayerCheckinsKey);
    if (raw == null || raw.isEmpty) {
      return <String, List<String>>{};
    }
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) {
        return <String, List<String>>{};
      }
      return parsed.map((key, value) {
        final list = value is List
            ? value.map((item) => item.toString()).toList()
            : <String>[];
        return MapEntry(key, list);
      });
    } catch (_) {
      return <String, List<String>>{};
    }
  }

  Future<void> savePrayerCheckins(Map<String, List<String>> checkins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prayerCheckinsKey, jsonEncode(checkins));
  }
}
