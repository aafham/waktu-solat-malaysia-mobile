import 'dart:async';

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
  String? errorMessage;

  List<PrayerZone> zones = <PrayerZone>[];
  PrayerZone? activeZone;
  DailyPrayerTimes? dailyPrayerTimes;

  Position? position;
  double? qiblaBearing;

  int tasbihCount = 0;

  bool notifyEnabled = true;
  bool vibrateEnabled = true;
  bool autoLocation = true;
  String manualZoneCode = 'SGR01';

  Timer? _refreshTimer;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    tasbihCount = await _tasbihStore.loadCount();
    notifyEnabled = await _tasbihStore.loadNotifyEnabled();
    vibrateEnabled = await _tasbihStore.loadVibrateEnabled();
    autoLocation = await _tasbihStore.loadAutoLocation();
    manualZoneCode = await _tasbihStore.loadManualZone();

    zones = await _prayerService.fetchZones();
    await _notificationService.initialize();

    await refreshPrayerData();

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });
  }

  Future<void> refreshPrayerData() async {
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
          orElse: () => zones.isNotEmpty ? zones.first : const PrayerZone(code: 'SGR01', state: 'Selangor', location: 'Default', latitude: 3.14, longitude: 101.69),
        );
      }

      final zoneCode = activeZone?.code ?? manualZoneCode;
      dailyPrayerTimes = await _prayerService.fetchDailyPrayerTimes(zoneCode);

      final lat = position?.latitude ?? activeZone?.latitude;
      final lng = position?.longitude ?? activeZone?.longitude;
      if (lat != null && lng != null) {
        qiblaBearing =
            _qiblaService.getQiblaBearing(latitude: lat, longitude: lng);
      }

      await _notificationService.schedulePrayerNotifications(
        prayers: dailyPrayerTimes?.entries ?? <PrayerTimeEntry>[],
        enableNotification: notifyEnabled,
        enableVibration: vibrateEnabled,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
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
  }

  Future<void> setManualZone(String value) async {
    manualZoneCode = value;
    await _tasbihStore.saveManualZone(value);
    await refreshPrayerData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
