import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/prayer_models.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/qibla_service.dart';
import '../services/tasbih_store.dart';

class AppController extends ChangeNotifier {
  AppController({
    required PrayerService prayerService,
    required LocationService locationService,
    required NotificationService notificationService,
    required QiblaService qiblaService,
    required TasbihStore tasbihStore,
  })  : _prayerService = prayerService,
        _locationService = locationService,
        _notificationService = notificationService,
        _qiblaService = qiblaService,
        _tasbihStore = tasbihStore;

  final PrayerService _prayerService;
  final LocationService _locationService;
  final NotificationService _notificationService;
  final QiblaService _qiblaService;
  final TasbihStore _tasbihStore;

  bool isLoading = true;
  bool isMonthlyLoading = false;
  String? errorMessage;

  List<PrayerZone> zones = <PrayerZone>[];
  PrayerZone? activeZone;
  DailyPrayerTimes? dailyPrayerTimes;
  MonthlyPrayerTimes? monthlyPrayerTimes;

  Position? position;
  double? qiblaBearing;

  int tasbihCount = 0;

  bool notifyEnabled = true;
  bool vibrateEnabled = true;
  bool autoLocation = true;
  String manualZoneCode = 'SGR01';
  double textScale = 1.0;
  bool highContrast = false;
  bool ramadhanMode = false;
  bool exactAlarmAllowed = true;

  Map<String, bool> prayerNotificationToggles = <String, bool>{};
  Map<String, String> prayerSoundProfiles = <String, String>{};
  List<String> favoriteZones = <String>[];
  List<String> recentZones = <String>[];
  final List<String> healthLogs = <String>[];

  Timer? _refreshTimer;
  DateTime _lastDayCheck = DateTime.now();
  bool _refreshing = false;

  int get apiSuccessCount => _prayerService.apiSuccessCount;
  int get apiFailureCount => _prayerService.apiFailureCount;
  int get cacheHitCount => _prayerService.cacheHitCount;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    tasbihCount = await _tasbihStore.loadCount();
    notifyEnabled = await _tasbihStore.loadNotifyEnabled();
    vibrateEnabled = await _tasbihStore.loadVibrateEnabled();
    autoLocation = await _tasbihStore.loadAutoLocation();
    manualZoneCode = await _tasbihStore.loadManualZone();
    textScale = await _tasbihStore.loadTextScale();
    highContrast = await _tasbihStore.loadHighContrast();
    ramadhanMode = await _tasbihStore.loadRamadhanMode();
    prayerNotificationToggles =
        await _tasbihStore.loadPrayerNotificationToggles();
    prayerSoundProfiles = await _tasbihStore.loadPrayerSoundProfiles();
    favoriteZones = await _tasbihStore.loadFavoriteZones();
    recentZones = await _tasbihStore.loadRecentZones();

    zones = await _prayerService.fetchZones();
    await _notificationService.initialize();
    exactAlarmAllowed = await _notificationService.canScheduleExactAlarms();

    await refreshPrayerData();
    await refreshMonthlyData();

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      if (_isDifferentDay(_lastDayCheck, now)) {
        _lastDayCheck = now;
        unawaited(refreshPrayerData());
        unawaited(refreshMonthlyData());
      }
      notifyListeners();
    });
  }

  Future<void> refreshPrayerData() async {
    if (_refreshing) {
      return;
    }
    _refreshing = true;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (autoLocation) {
        position = await _locationService.getCurrentPosition();
        activeZone = _prayerService.nearestZone(
          latitude: position!.latitude,
          longitude: position!.longitude,
          zones: zones,
        );
      } else {
        activeZone = zones.firstWhere(
          (z) => z.code == manualZoneCode,
          orElse: () => zones.isNotEmpty
              ? zones.first
              : const PrayerZone(
                  code: 'SGR01',
                  state: 'Selangor',
                  location: 'Default',
                  latitude: 3.14,
                  longitude: 101.69,
                ),
        );
      }

      final zoneCode = activeZone?.code ?? manualZoneCode;
      manualZoneCode = zoneCode;
      await _tasbihStore.saveManualZone(zoneCode);
      await _pushRecentZone(zoneCode);

      dailyPrayerTimes = await _prayerService.fetchDailyPrayerTimes(zoneCode);
      _pushHealthLog('daily_ok:$zoneCode');

      final lat = position?.latitude ?? activeZone?.latitude;
      final lng = position?.longitude ?? activeZone?.longitude;
      if (lat != null && lng != null) {
        qiblaBearing =
            _qiblaService.getQiblaBearing(latitude: lat, longitude: lng);
      }

      try {
        await _notificationService.schedulePrayerNotifications(
          prayers: dailyPrayerTimes?.entries ?? <PrayerTimeEntry>[],
          enableNotification: notifyEnabled,
          enableVibration: vibrateEnabled,
        enabledPrayerNames: prayerNotificationToggles.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toSet(),
          prayerSoundProfiles: prayerSoundProfiles,
        );
      } catch (_) {
        // Non-critical: data waktu solat sudah berjaya diambil.
      }
    } catch (e) {
      _pushHealthLog('daily_err:${e.runtimeType}');
      errorMessage = _friendlyError(e);
    } finally {
      isLoading = false;
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshMonthlyData() async {
    final zoneCode = activeZone?.code ?? manualZoneCode;
    isMonthlyLoading = true;
    notifyListeners();
    try {
      monthlyPrayerTimes = await _prayerService.fetchMonthlyPrayerTimes(
        zoneCode,
        month: DateTime.now(),
      );
      _pushHealthLog('monthly_ok:$zoneCode');
    } catch (_) {
      // Monthly data is optional.
      _pushHealthLog('monthly_err');
    } finally {
      isMonthlyLoading = false;
      notifyListeners();
    }
  }

  PrayerTimeEntry? get nextPrayer {
    final entries = dailyPrayerTimes?.entries;
    if (entries == null || entries.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    for (final entry in entries) {
      if (entry.time.isAfter(now)) {
        return entry;
      }
    }
    return null;
  }

  Duration? get timeToNextPrayer {
    final next = nextPrayer;
    if (next == null) {
      return null;
    }
    return next.time.difference(DateTime.now());
  }

  Future<void> incrementTasbih() async {
    tasbihCount += 1;
    await _tasbihStore.saveCount(tasbihCount);
    notifyListeners();
  }

  Future<void> resetTasbih() async {
    tasbihCount = 0;
    await _tasbihStore.saveCount(tasbihCount);
    notifyListeners();
  }

  Future<void> setNotifyEnabled(bool value) async {
    notifyEnabled = value;
    await _tasbihStore.saveNotifyEnabled(value);
    await refreshPrayerData();
  }

  Future<void> setVibrateEnabled(bool value) async {
    vibrateEnabled = value;
    await _tasbihStore.saveVibrateEnabled(value);
    await refreshPrayerData();
  }

  Future<void> setAutoLocation(bool value) async {
    autoLocation = value;
    await _tasbihStore.saveAutoLocation(value);
    await refreshPrayerData();
    await refreshMonthlyData();
  }

  Future<void> setManualZone(String value) async {
    manualZoneCode = value;
    await _tasbihStore.saveManualZone(value);
    await _pushRecentZone(value);
    await refreshPrayerData();
    await refreshMonthlyData();
  }

  Future<void> setPrayerNotifyEnabled(String prayerName, bool value) async {
    prayerNotificationToggles[prayerName] = value;
    await _tasbihStore.savePrayerNotificationToggle(prayerName, value);
    await refreshPrayerData();
  }

  Future<void> toggleFavoriteZone(String zoneCode) async {
    if (favoriteZones.contains(zoneCode)) {
      favoriteZones = favoriteZones.where((z) => z != zoneCode).toList();
    } else {
      favoriteZones = <String>[zoneCode, ...favoriteZones]
          .take(8)
          .toList(growable: false);
    }
    await _tasbihStore.saveFavoriteZones(favoriteZones);
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    textScale = value.clamp(0.9, 1.4).toDouble();
    await _tasbihStore.saveTextScale(textScale);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    highContrast = value;
    await _tasbihStore.saveHighContrast(value);
    notifyListeners();
  }

  Future<void> setRamadhanMode(bool value) async {
    ramadhanMode = value;
    await _tasbihStore.saveRamadhanMode(value);
    notifyListeners();
  }

  Future<void> setPrayerSoundProfile(String prayerName, String profile) async {
    prayerSoundProfiles[prayerName] = profile;
    await _tasbihStore.savePrayerSoundProfile(prayerName, profile);
    await refreshPrayerData();
  }

  Future<void> snoozeNextPrayer(int minutes) async {
    final next = nextPrayer;
    if (!notifyEnabled || next == null) {
      return;
    }
    await _notificationService.scheduleSnoozeReminder(
      prayerName: next.name,
      minutes: minutes,
      enableVibration: vibrateEnabled,
    );
  }

  String exportSettingsJson() {
    return jsonEncode(<String, dynamic>{
      'notifyEnabled': notifyEnabled,
      'vibrateEnabled': vibrateEnabled,
      'autoLocation': autoLocation,
      'manualZoneCode': manualZoneCode,
      'textScale': textScale,
      'highContrast': highContrast,
      'ramadhanMode': ramadhanMode,
      'prayerNotificationToggles': prayerNotificationToggles,
      'prayerSoundProfiles': prayerSoundProfiles,
      'favoriteZones': favoriteZones,
      'recentZones': recentZones,
    });
  }

  Future<void> importSettingsJson(String raw) async {
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    notifyEnabled = parsed['notifyEnabled'] as bool? ?? notifyEnabled;
    vibrateEnabled = parsed['vibrateEnabled'] as bool? ?? vibrateEnabled;
    autoLocation = parsed['autoLocation'] as bool? ?? autoLocation;
    manualZoneCode = parsed['manualZoneCode'] as String? ?? manualZoneCode;
    textScale = (parsed['textScale'] as num?)?.toDouble() ?? textScale;
    highContrast = parsed['highContrast'] as bool? ?? highContrast;
    ramadhanMode = parsed['ramadhanMode'] as bool? ?? ramadhanMode;

    final toggles = parsed['prayerNotificationToggles'];
    if (toggles is Map<String, dynamic>) {
      prayerNotificationToggles =
          toggles.map((k, v) => MapEntry(k, v == true));
    }

    final sounds = parsed['prayerSoundProfiles'];
    if (sounds is Map<String, dynamic>) {
      prayerSoundProfiles = sounds.map(
        (k, v) => MapEntry(k, (v ?? 'default').toString()),
      );
    }

    final fav = parsed['favoriteZones'];
    if (fav is List) {
      favoriteZones = fav.map((e) => e.toString()).toList();
    }
    final rec = parsed['recentZones'];
    if (rec is List) {
      recentZones = rec.map((e) => e.toString()).toList();
    }

    await _tasbihStore.saveNotifyEnabled(notifyEnabled);
    await _tasbihStore.saveVibrateEnabled(vibrateEnabled);
    await _tasbihStore.saveAutoLocation(autoLocation);
    await _tasbihStore.saveManualZone(manualZoneCode);
    await _tasbihStore.saveTextScale(textScale);
    await _tasbihStore.saveHighContrast(highContrast);
    await _tasbihStore.saveRamadhanMode(ramadhanMode);
    await _tasbihStore.saveFavoriteZones(favoriteZones);
    await _tasbihStore.saveRecentZones(recentZones);
    for (final entry in prayerNotificationToggles.entries) {
      await _tasbihStore.savePrayerNotificationToggle(entry.key, entry.value);
    }
    for (final entry in prayerSoundProfiles.entries) {
      await _tasbihStore.savePrayerSoundProfile(entry.key, entry.value);
    }

    await refreshPrayerData();
    await refreshMonthlyData();
    notifyListeners();
  }

  String exportMonthlyAsCsv() {
    final monthly = monthlyPrayerTimes;
    if (monthly == null) {
      return '';
    }
    final rows = <String>[
      'Date,Imsak,Subuh,Syuruk,Zohor,Asar,Maghrib,Isyak',
    ];
    for (final day in monthly.days) {
      String findTime(String name) {
        final entry = day.entries.firstWhere((e) => e.name == name);
        return '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}';
      }

      final d =
          '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';
      rows.add('$d,${findTime('Imsak')},${findTime('Subuh')},${findTime('Syuruk')},${findTime('Zohor')},${findTime('Asar')},${findTime('Maghrib')},${findTime('Isyak')}');
    }
    return rows.join('\n');
  }

  String? nearbyMosqueMapUrl() {
    final lat = position?.latitude ?? activeZone?.latitude;
    final lng = position?.longitude ?? activeZone?.longitude;
    if (lat == null || lng == null) {
      return null;
    }
    return 'https://www.google.com/maps/search/?api=1&query=masjid%20near%20$lat,$lng';
  }

  Future<void> _pushRecentZone(String zoneCode) async {
    recentZones = <String>[
      zoneCode,
      ...recentZones.where((code) => code != zoneCode),
    ].take(8).toList(growable: false);
    await _tasbihStore.saveRecentZones(recentZones);
  }

  bool isZoneFavorite(String zoneCode) => favoriteZones.contains(zoneCode);

  bool _isDifferentDay(DateTime a, DateTime b) =>
      a.year != b.year || a.month != b.month || a.day != b.day;

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('location') || text.contains('lokasi')) {
      return 'Lokasi tidak tersedia. Sila aktifkan GPS atau pilih zon manual.';
    }
    if (text.contains('timeout')) {
      return 'Sambungan perlahan. Tarik ke bawah untuk cuba semula.';
    }
    if (text.contains('tidak tersedia')) {
      return 'Data belum tersedia dari server. Data cache akan digunakan bila ada.';
    }
    return 'Tidak dapat memuat data sekarang. Sila cuba semula sekejap lagi.';
  }

  void _pushHealthLog(String event) {
    final now = DateTime.now();
    final ts =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    healthLogs.insert(0, '$ts $event');
    if (healthLogs.length > 40) {
      healthLogs.removeLast();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
