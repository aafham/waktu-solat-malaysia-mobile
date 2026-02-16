import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _lastErrorRaw = '';
  DateTime? lastPrayerDataUpdatedAt;
  String lastPrayerDataSource = 'unknown';

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
  bool onboardingSeen = false;
  bool travelModeEnabled = true;
  bool fastingMondayThursdayEnabled = false;
  bool fastingAyyamulBidhEnabled = false;

  Map<String, bool> prayerNotificationToggles = <String, bool>{};
  Map<String, String> prayerSoundProfiles = <String, String>{};
  List<String> favoriteZones = <String>[];
  List<String> recentZones = <String>[];
  Map<String, int> tasbihDailyStats = <String, int>{};
  final List<String> healthLogs = <String>[];

  Timer? _refreshTimer;
  Timer? _travelTimer;
  StreamSubscription? _notificationResponseSub;
  DateTime _lastDayCheck = DateTime.now();
  bool _refreshing = false;

  int get apiSuccessCount => _prayerService.apiSuccessCount;
  int get apiFailureCount => _prayerService.apiFailureCount;
  int get cacheHitCount => _prayerService.cacheHitCount;
  bool get isUsingCachedPrayerData => lastPrayerDataSource == 'cache';
  bool get isReady => zones.isNotEmpty || dailyPrayerTimes != null || !isLoading;
  int get tasbihTodayCount => tasbihDailyStats[_dateKey(DateTime.now())] ?? 0;
  int get tasbihWeekCount {
    final now = DateTime.now();
    var total = 0;
    for (var i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      total += tasbihDailyStats[_dateKey(day)] ?? 0;
    }
    return total;
  }
  int get tasbihBestDay {
    if (tasbihDailyStats.isEmpty) {
      return 0;
    }
    return tasbihDailyStats.values.reduce((a, b) => a > b ? a : b);
  }
  int get tasbihStreakDays {
    var streak = 0;
    var cursor = DateTime.now();
    while ((tasbihDailyStats[_dateKey(cursor)] ?? 0) > 0) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
  String get prayerDataFreshnessLabel {
    final updatedAt = lastPrayerDataUpdatedAt;
    if (updatedAt == null) {
      return 'Belum dikemas kini';
    }
    final age = DateTime.now().difference(updatedAt);
    final ageText = age.inMinutes <= 0 ? 'baru sahaja' : '${age.inMinutes} min lalu';
    final source = isUsingCachedPrayerData ? 'Data simpanan' : 'Data langsung';
    return '$source | $ageText';
  }

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
    onboardingSeen = await _tasbihStore.loadOnboardingSeen();
    travelModeEnabled = await _tasbihStore.loadTravelModeEnabled();
    fastingMondayThursdayEnabled =
        await _tasbihStore.loadFastingMonThuEnabled();
    fastingAyyamulBidhEnabled =
        await _tasbihStore.loadFastingAyyamulBidhEnabled();
    tasbihDailyStats = await _tasbihStore.loadTasbihDailyStats();

    zones = await _prayerService.fetchZones();
    await _notificationService.initialize();
    exactAlarmAllowed = await _notificationService.canScheduleExactAlarms();
    _notificationResponseSub = _notificationService.responses.listen((response) {
      if (response.actionId == 'done') {
        _pushHealthLog('notif_action:done');
      } else if (response.actionId == 'snooze_5') {
        _pushHealthLog('notif_action:snooze_5');
      }
    });

    await refreshPrayerData();
    await refreshMonthlyData();
    await _scheduleFastingReminders();
    await _updateWidgetData();

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
    _travelTimer?.cancel();
    _travelTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      unawaited(_checkTravelAutoZone());
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
      final successBefore = _prayerService.apiSuccessCount;
      final cacheBefore = _prayerService.cacheHitCount;

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
      lastPrayerDataUpdatedAt = DateTime.now();
      if (_prayerService.apiSuccessCount > successBefore) {
        lastPrayerDataSource = 'live';
      } else if (_prayerService.cacheHitCount > cacheBefore) {
        lastPrayerDataSource = 'cache';
      } else {
        lastPrayerDataSource = 'unknown';
      }
      _lastErrorRaw = '';

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
      await _updateWidgetData();
    } catch (e) {
      _pushHealthLog('daily_err:${e.runtimeType}');
      _lastErrorRaw = e.toString().toLowerCase();
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
      await _prayerService.fetchMonthlyPrayerTimes(
        zoneCode,
        month: DateTime.now().add(const Duration(days: 32)),
      );
      await _scheduleFastingReminders();
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
    await _addTasbihDaily(1);
    await _updateWidgetData();
    notifyListeners();
  }

  Future<void> addTasbihBatch(int count) async {
    if (count <= 0) {
      return;
    }
    tasbihCount += count;
    await _tasbihStore.saveCount(tasbihCount);
    await _addTasbihDaily(count);
    await _updateWidgetData();
    notifyListeners();
  }

  Future<void> resetTasbih() async {
    tasbihCount = 0;
    await _tasbihStore.saveCount(tasbihCount);
    await _updateWidgetData();
    notifyListeners();
  }

  Future<void> setNotifyEnabled(bool value) async {
    notifyEnabled = value;
    await _tasbihStore.saveNotifyEnabled(value);
    await refreshPrayerData();
    await _scheduleFastingReminders();
  }

  Future<void> setVibrateEnabled(bool value) async {
    vibrateEnabled = value;
    await _tasbihStore.saveVibrateEnabled(value);
    await refreshPrayerData();
    await _scheduleFastingReminders();
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
    await _scheduleFastingReminders();
    notifyListeners();
  }

  Future<void> setPrayerSoundProfile(String prayerName, String profile) async {
    prayerSoundProfiles[prayerName] = profile;
    await _tasbihStore.savePrayerSoundProfile(prayerName, profile);
    await refreshPrayerData();
  }

  Future<void> previewPrayerSound(String prayerName) async {
    final profile = prayerSoundProfiles[prayerName] ?? 'default';
    await _notificationService.showPrayerSoundPreview(
      prayerName: prayerName,
      soundProfile: profile,
      enableVibration: vibrateEnabled,
    );
  }

  Future<void> setTravelModeEnabled(bool value) async {
    travelModeEnabled = value;
    await _tasbihStore.saveTravelModeEnabled(value);
    notifyListeners();
  }

  Future<void> setFastingMondayThursdayEnabled(bool value) async {
    fastingMondayThursdayEnabled = value;
    await _tasbihStore.saveFastingMonThuEnabled(value);
    await _scheduleFastingReminders();
    notifyListeners();
  }

  Future<void> setFastingAyyamulBidhEnabled(bool value) async {
    fastingAyyamulBidhEnabled = value;
    await _tasbihStore.saveFastingAyyamulBidhEnabled(value);
    await _scheduleFastingReminders();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingSeen = true;
    await _tasbihStore.saveOnboardingSeen(true);
    notifyListeners();
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
      'travelModeEnabled': travelModeEnabled,
      'fastingMondayThursdayEnabled': fastingMondayThursdayEnabled,
      'fastingAyyamulBidhEnabled': fastingAyyamulBidhEnabled,
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
    travelModeEnabled =
        parsed['travelModeEnabled'] as bool? ?? travelModeEnabled;
    fastingMondayThursdayEnabled = parsed['fastingMondayThursdayEnabled']
            as bool? ??
        fastingMondayThursdayEnabled;
    fastingAyyamulBidhEnabled =
        parsed['fastingAyyamulBidhEnabled'] as bool? ??
            fastingAyyamulBidhEnabled;

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
    await _tasbihStore.saveTravelModeEnabled(travelModeEnabled);
    await _tasbihStore.saveFastingMonThuEnabled(fastingMondayThursdayEnabled);
    await _tasbihStore.saveFastingAyyamulBidhEnabled(
      fastingAyyamulBidhEnabled,
    );
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
    await _scheduleFastingReminders();
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

  String exportMonthlyAsIcs() {
    final monthly = monthlyPrayerTimes;
    if (monthly == null) {
      return '';
    }
    final b = StringBuffer();
    b.writeln('BEGIN:VCALENDAR');
    b.writeln('VERSION:2.0');
    b.writeln('PRODID:-//Waktu Solat Malaysia//MS');
    for (final day in monthly.days) {
      for (final entry in day.entries) {
        final start = _icsDate(entry.time);
        final end = _icsDate(entry.time.add(const Duration(minutes: 20)));
        b.writeln('BEGIN:VEVENT');
        b.writeln('UID:${entry.name}-${start}@waktusolat');
        b.writeln('DTSTAMP:${_icsDate(DateTime.now())}');
        b.writeln('DTSTART:$start');
        b.writeln('DTEND:$end');
        b.writeln('SUMMARY:Waktu ${entry.name}');
        b.writeln('DESCRIPTION:${activeZone?.label ?? '-'}');
        b.writeln('END:VEVENT');
      }
    }
    b.writeln('END:VCALENDAR');
    return b.toString();
  }

  String exportTodayAsIcs() {
    final daily = dailyPrayerTimes;
    if (daily == null) {
      return '';
    }
    final b = StringBuffer();
    b.writeln('BEGIN:VCALENDAR');
    b.writeln('VERSION:2.0');
    b.writeln('PRODID:-//Waktu Solat Malaysia//MS');
    for (final entry in daily.entries) {
      final start = _icsDate(entry.time);
      final end = _icsDate(entry.time.add(const Duration(minutes: 20)));
      b.writeln('BEGIN:VEVENT');
      b.writeln('UID:${entry.name}-${start}@waktusolat');
      b.writeln('DTSTAMP:${_icsDate(DateTime.now())}');
      b.writeln('DTSTART:$start');
      b.writeln('DTEND:$end');
      b.writeln('SUMMARY:Waktu ${entry.name}');
      b.writeln('DESCRIPTION:${activeZone?.label ?? '-'}');
      b.writeln('END:VEVENT');
    }
    b.writeln('END:VCALENDAR');
    return b.toString();
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
      return 'Data belum tersedia dari pelayan. Data simpanan akan digunakan bila ada.';
    }
    return 'Tidak dapat memuat data sekarang. Sila cuba semula sekejap lagi.';
  }

  String? get errorActionLabel {
    if (errorMessage == null) {
      return null;
    }
    if (_lastErrorRaw.contains('location') || _lastErrorRaw.contains('lokasi')) {
      return 'Buka tetapan lokasi';
    }
    if (_lastErrorRaw.contains('notification') || _lastErrorRaw.contains('notifikasi')) {
      return 'Buka tetapan aplikasi';
    }
    if (_lastErrorRaw.contains('server') || _lastErrorRaw.contains('timeout')) {
      return 'Guna zon manual';
    }
    return null;
  }

  Future<void> runErrorAction() async {
    final label = errorActionLabel;
    if (label == null) {
      return;
    }
    if (label == 'Buka tetapan lokasi') {
      await Geolocator.openLocationSettings();
      return;
    }
    if (label == 'Buka tetapan aplikasi') {
      await Geolocator.openAppSettings();
      return;
    }
    if (label == 'Guna zon manual') {
      await setAutoLocation(false);
      return;
    }
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

  Future<void> _scheduleFastingReminders() async {
    final monthly = monthlyPrayerTimes;
    if (monthly == null) {
      return;
    }
    await _notificationService.scheduleFastingReminders(
      monthlyDays: monthly.days,
      enableNotification: notifyEnabled,
      enableMondayThursday: fastingMondayThursdayEnabled,
      enableAyyamulBidh: fastingAyyamulBidhEnabled,
      enableVibration: vibrateEnabled,
    );
  }

  Future<void> _checkTravelAutoZone() async {
    if (!autoLocation || !travelModeEnabled || zones.isEmpty || _refreshing) {
      return;
    }
    try {
      final newPos = await _locationService.getCurrentPosition();
      final nearest = _prayerService.nearestZone(
        latitude: newPos.latitude,
        longitude: newPos.longitude,
        zones: zones,
      );
      if (activeZone == null || nearest.code != activeZone!.code) {
        position = newPos;
        activeZone = nearest;
        manualZoneCode = nearest.code;
        await _tasbihStore.saveManualZone(nearest.code);
        _pushHealthLog('travel_zone:${nearest.code}');
        await refreshPrayerData();
        await refreshMonthlyData();
      }
    } catch (_) {
      _pushHealthLog('travel_check_err');
    }
  }

  Future<void> _updateWidgetData() async {
    final next = nextPrayer;
    final countdown = timeToNextPrayer;
    final payload = <String, String>{
      'widget_title': 'Waktu Solat',
      'widget_subtitle': next == null
          ? 'Tiada waktu seterusnya'
          : '${next.name} ${next.time.hour.toString().padLeft(2, '0')}:${next.time.minute.toString().padLeft(2, '0')}',
      'widget_countdown': _formatWidgetCountdown(countdown),
      'widget_tasbih': '$tasbihCount',
    };
    await _saveWidgetPayload(payload);
  }

  Future<void> _saveWidgetPayload(Map<String, String> data) async {
    final store = await SharedPreferences.getInstance();
    for (final entry in data.entries) {
      await store.setString(entry.key, entry.value);
    }
  }

  String _formatWidgetCountdown(Duration? d) {
    if (d == null || d.isNegative) {
      return '--:--:--';
    }
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _addTasbihDaily(int count) async {
    final key = _dateKey(DateTime.now());
    tasbihDailyStats[key] = (tasbihDailyStats[key] ?? 0) + count;
    await _tasbihStore.saveTasbihDailyStats(tasbihDailyStats);
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _icsDate(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}${utc.month.toString().padLeft(2, '0')}${utc.day.toString().padLeft(2, '0')}T${utc.hour.toString().padLeft(2, '0')}${utc.minute.toString().padLeft(2, '0')}${utc.second.toString().padLeft(2, '0')}Z';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _travelTimer?.cancel();
    _notificationResponseSub?.cancel();
    _notificationService.dispose();
    super.dispose();
  }
}
