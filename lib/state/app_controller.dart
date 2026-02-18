import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/prayer_models.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_calculation_service.dart';
import '../services/prayer_service.dart';
import '../services/qibla_service.dart';
import '../services/tasbih_store.dart';
import '../services/widget_update_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    required PrayerService prayerService,
    required LocationService locationService,
    required NotificationService notificationService,
    required PrayerCalculationService prayerCalculationService,
    required QiblaService qiblaService,
    required TasbihStore tasbihStore,
    WidgetUpdateService widgetUpdateService = const WidgetUpdateService(),
  })  : _prayerService = prayerService,
        _locationService = locationService,
        _notificationService = notificationService,
        _prayerCalculationService = prayerCalculationService,
        _qiblaService = qiblaService,
        _tasbihStore = tasbihStore,
        _widgetUpdateService = widgetUpdateService;

  final PrayerService _prayerService;
  final LocationService _locationService;
  final NotificationService _notificationService;
  final PrayerCalculationService _prayerCalculationService;
  final QiblaService _qiblaService;
  final TasbihStore _tasbihStore;
  final WidgetUpdateService _widgetUpdateService;

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
  MonthlyPrayerTimes? nextMonthlyPrayerTimes;

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
  bool locationPermissionDenied = false;
  bool fastingMondayThursdayEnabled = false;
  bool fastingAyyamulBidhEnabled = false;
  bool respectSilentMode = true;
  int notificationLeadMinutes = 0;
  int tasbihCycleTarget = 33;
  bool tasbihAutoResetDaily = false;
  String languageCode = 'en';
  int tasbihLifetimeCount = 0;

  Map<String, bool> prayerNotificationToggles = <String, bool>{};
  Map<String, String> prayerSoundProfiles = <String, String>{};
  String prayerCalculationMethod = 'JAKIM';
  String asarMethod = "Shafi'i";
  String highLatitudeRule = 'Middle of the Night';
  Map<String, int> manualPrayerAdjustments = <String, int>{};
  int hijriOffsetDays = 0;
  List<String> favoriteZones = <String>[];
  List<String> recentZones = <String>[];
  Map<String, int> tasbihDailyStats = <String, int>{};
  Map<String, List<String>> prayerCheckinsByDate = <String, List<String>>{};
  final List<String> healthLogs = <String>[];

  Timer? _refreshTimer;
  Timer? _travelTimer;
  StreamSubscription? _notificationResponseSub;
  DateTime _lastDayCheck = DateTime.now();
  bool _refreshing = false;
  Timer? _retryTimer;
  Timer? _fastingRescheduleDebounce;
  int _retryAttempt = 0;
  String? _errorActionCode;

  int get apiSuccessCount => _prayerService.apiSuccessCount;
  int get apiFailureCount => _prayerService.apiFailureCount;
  int get cacheHitCount => _prayerService.cacheHitCount;
  bool get isUsingCachedPrayerData => lastPrayerDataSource == 'cache';
  bool get isReady =>
      zones.isNotEmpty || dailyPrayerTimes != null || !isLoading;
  int get tasbihTodayCount => tasbihDailyStats[_dateKey(DateTime.now())] ?? 0;
  bool get isEnglish => languageCode == 'en';
  bool get requiresManualZonePicker =>
      !autoLocation || locationPermissionDenied;
  List<String> get prayerNamesOrdered => const <String>[
        'Imsak',
        'Subuh',
        'Syuruk',
        'Zohor',
        'Asar',
        'Maghrib',
        'Isyak',
      ];
  List<String> get availableSoundProfiles => const <String>[
        'default',
        'silent',
      ];
  String get globalAzanSoundProfile {
    for (final name in prayerNamesOrdered) {
      final profile = prayerSoundProfiles[name];
      if (profile != null && profile.isNotEmpty) {
        return profile;
      }
    }
    return 'default';
  }

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

  List<String> get todayPrayerCheckins =>
      prayerCheckinsByDate[_dateKey(DateTime.now())] ?? <String>[];
  int get todayPrayerCompletedCount => todayPrayerCheckins.length;
  int get todayPrayerTargetCount {
    final names =
        dailyPrayerTimes?.entries.map((e) => e.name).toList() ?? <String>[];
    final filtered = names
        .where((name) =>
            name == 'Subuh' ||
            name == 'Zohor' ||
            name == 'Asar' ||
            name == 'Maghrib' ||
            name == 'Isyak')
        .toList();
    return filtered.isEmpty ? 5 : filtered.length;
  }

  double get todayPrayerProgress {
    final target = todayPrayerTargetCount;
    if (target == 0) {
      return 0;
    }
    return (todayPrayerCompletedCount / target).clamp(0.0, 1.0);
  }

  List<Map<String, Object>> get prayerHistory7Days {
    final now = DateTime.now();
    final target = todayPrayerTargetCount == 0 ? 5 : todayPrayerTargetCount;
    final rows = <Map<String, Object>>[];
    for (var i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = _dateKey(day);
      final done = (prayerCheckinsByDate[key] ?? const <String>[]).length;
      rows.add(<String, Object>{
        'date': day,
        'done': done,
        'target': target,
      });
    }
    return rows;
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
      return tr('Belum dikemas kini', 'Not updated yet');
    }
    final age = DateTime.now().difference(updatedAt);
    final ageText = age.inMinutes <= 0
        ? tr('baru sahaja', 'just now')
        : tr('${age.inMinutes} min lalu', '${age.inMinutes} min ago');
    final source = isUsingCachedPrayerData
        ? tr('Data simpanan', 'Cached data')
        : lastPrayerDataSource == 'local_calc'
            ? tr('Kiraan tempatan', 'Local calculation')
            : tr('Data langsung', 'Live data');
    return '$source | $ageText';
  }

  String? get todayHijriHeaderLabel {
    final parts = _activeHijriPartsNow();
    if (parts == null) {
      return null;
    }
    return _formatHijriParts(parts);
  }

  String get todayHijriPreviewLabel {
    final parts = _activeHijriPartsNow();
    final date =
        parts == null ? t('hijri_unavailable') : _formatHijriParts(parts);
    return t(
      'hijri_today_preview',
      params: <String, String>{
        'date': date,
        'offset': _formatOffset(hijriOffsetDays),
      },
    );
  }

  (int, int, int)? _activeHijriPartsNow() {
    final parsed = _parseHijriParts(dailyPrayerTimes?.hijriDate);
    if (parsed == null) {
      return null;
    }
    final maghrib = _findPrayerEntry('Maghrib');
    final now = DateTime.now();
    final dayShift = (maghrib != null && now.isBefore(maghrib.time)) ? -1 : 0;
    return _applyHijriOffsetToParts(
      day: parsed.$1,
      month: parsed.$2,
      year: parsed.$3,
      offset: hijriOffsetDays + dayShift,
    );
  }

  PrayerTimeEntry? _findPrayerEntry(String name) {
    final entries = dailyPrayerTimes?.entries;
    if (entries == null || entries.isEmpty) {
      return null;
    }
    for (final entry in entries) {
      if (entry.name == name) {
        return entry;
      }
    }
    return null;
  }

  int? get _todayHijriMonth {
    return _activeHijriPartsNow()?.$2;
  }

  bool get isHijriRamadanToday => _todayHijriMonth == 9;

  bool get isRamadanModeActive => ramadhanMode || isHijriRamadanToday;

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
    respectSilentMode = await _tasbihStore.loadRespectSilentMode();
    tasbihDailyStats = await _tasbihStore.loadTasbihDailyStats();
    prayerCheckinsByDate = await _tasbihStore.loadPrayerCheckins();
    notificationLeadMinutes = await _tasbihStore.loadNotificationLeadMinutes();
    tasbihCycleTarget = await _tasbihStore.loadTasbihCycleTarget();
    tasbihAutoResetDaily = await _tasbihStore.loadTasbihAutoResetDaily();
    languageCode = await _tasbihStore.loadLanguageCode();
    tasbihLifetimeCount = await _tasbihStore.loadTasbihLifetimeCount();
    prayerCalculationMethod = await _tasbihStore.loadPrayerCalculationMethod();
    asarMethod = await _tasbihStore.loadAsarMethod();
    highLatitudeRule = await _tasbihStore.loadHighLatitudeRule();
    manualPrayerAdjustments = await _tasbihStore.loadManualPrayerAdjustments();
    hijriOffsetDays = await _tasbihStore.loadHijriOffsetDays();
    _normalizeManualAdjustments();
    if (tasbihLifetimeCount == 0 && tasbihCount > 0) {
      tasbihLifetimeCount = tasbihCount;
      await _tasbihStore.saveTasbihLifetimeCount(tasbihLifetimeCount);
    }
    await _ensureTasbihDailyReset();

    zones = await _prayerService.fetchZones();
    await _notificationService.initialize();
    exactAlarmAllowed = await _notificationService.canScheduleExactAlarms();
    _notificationResponseSub =
        _notificationService.responses.listen((response) {
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
        try {
          position = await _locationService.getCurrentPosition();
          locationPermissionDenied = false;
          activeZone = _prayerService.nearestZone(
            latitude: position!.latitude,
            longitude: position!.longitude,
            zones: zones,
          );
        } catch (e) {
          final text = e.toString().toLowerCase();
          if (text.contains('permission') ||
              text.contains('denied') ||
              text.contains('ditolak')) {
            locationPermissionDenied = true;
            autoLocation = false;
            await _tasbihStore.saveAutoLocation(false);
          } else {
            rethrow;
          }
        }
      }

      if (!autoLocation) {
        position = null;
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

      DailyPrayerTimes fetched;
      var source = 'unknown';
      try {
        fetched = await _prayerService.fetchDailyPrayerTimes(zoneCode);
        if (_prayerService.apiSuccessCount > successBefore) {
          source = 'live';
        } else if (_prayerService.cacheHitCount > cacheBefore) {
          source = 'cache';
        }
      } catch (_) {
        source = 'local_calc';
        fetched = _prayerCalculationService.calculateDaily(
          zone: activeZone!,
          date: DateTime.now(),
          calculationMethod: prayerCalculationMethod,
          asarMethod: asarMethod,
          highLatitudeRule: highLatitudeRule,
        );
        _pushHealthLog('daily_local_calc:$zoneCode');
      }

      final shouldOverrideApi = _isCustomCalculationPreferenceEnabled();
      final baseDaily = shouldOverrideApi
          ? _prayerCalculationService.calculateDaily(
              zone: activeZone!,
              date: DateTime.now(),
              calculationMethod: prayerCalculationMethod,
              asarMethod: asarMethod,
              highLatitudeRule: highLatitudeRule,
            )
          : fetched;

      dailyPrayerTimes = _applyManualAdjustmentsToDaily(baseDaily);
      _pushHealthLog('daily_ok:$zoneCode');
      lastPrayerDataUpdatedAt = DateTime.now();
      lastPrayerDataSource = shouldOverrideApi ? 'local_calc' : source;
      _lastErrorRaw = '';
      _errorActionCode = null;

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
          leadMinutes: notificationLeadMinutes,
          respectSilentMode: respectSilentMode,
        );
      } catch (_) {
        // Non-critical: data waktu solat sudah berjaya diambil.
      }
      await _updateWidgetData();
      _retryAttempt = 0;
      _retryTimer?.cancel();
    } catch (e) {
      _pushHealthLog('daily_err:${e.runtimeType}');
      _lastErrorRaw = e.toString().toLowerCase();
      if (_lastErrorRaw.contains('notification') ||
          _lastErrorRaw.contains('notifikasi')) {
        _errorActionCode = 'open_app';
      }
      errorMessage = _friendlyError(e);
      _scheduleAutoRetry();
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
      nextMonthlyPrayerTimes = await _prayerService.fetchMonthlyPrayerTimes(
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
    final sorted = [...entries]..sort((a, b) => a.time.compareTo(b.time));

    final now = DateTime.now();
    for (final entry in sorted) {
      if (entry.time.isAfter(now)) {
        return entry;
      }
    }
    PrayerTimeEntry? subuh;
    for (final entry in sorted) {
      if (entry.name == 'Subuh') {
        subuh = entry;
        break;
      }
    }
    final fallback = subuh ?? sorted.first;
    return PrayerTimeEntry(
      name: fallback.name,
      time: fallback.time.add(const Duration(days: 1)),
    );
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
    tasbihLifetimeCount += 1;
    await _tasbihStore.saveCount(tasbihCount);
    await _tasbihStore.saveTasbihLifetimeCount(tasbihLifetimeCount);
    await _addTasbihDaily(1);
    await _updateWidgetData();
    notifyListeners();
  }

  Future<void> addTasbihBatch(int count) async {
    if (count <= 0) {
      return;
    }
    tasbihCount += count;
    tasbihLifetimeCount += count;
    await _tasbihStore.saveCount(tasbihCount);
    await _tasbihStore.saveTasbihLifetimeCount(tasbihLifetimeCount);
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

  Future<void> decrementTasbih() async {
    if (tasbihCount <= 0) {
      return;
    }
    tasbihCount -= 1;
    if (tasbihLifetimeCount > 0) {
      tasbihLifetimeCount -= 1;
    }
    await _tasbihStore.saveCount(tasbihCount);
    await _tasbihStore.saveTasbihLifetimeCount(tasbihLifetimeCount);
    await _subtractTasbihDaily(1);
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
    if (value) {
      locationPermissionDenied = false;
    }
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

  Future<void> setNotificationLeadMinutes(int value) async {
    notificationLeadMinutes = value.clamp(0, 30);
    await _tasbihStore.saveNotificationLeadMinutes(notificationLeadMinutes);
    await refreshPrayerData();
  }

  Future<void> toggleFavoriteZone(String zoneCode) async {
    if (favoriteZones.contains(zoneCode)) {
      favoriteZones = favoriteZones.where((z) => z != zoneCode).toList();
    } else {
      favoriteZones =
          <String>[zoneCode, ...favoriteZones].take(8).toList(growable: false);
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
    if (ramadhanMode == value) {
      return;
    }
    ramadhanMode = value;
    notifyListeners();
    await _tasbihStore.saveRamadhanMode(value);
    _queueFastingReminderReschedule();
  }

  Future<void> setPrayerSoundProfile(String prayerName, String profile) async {
    prayerSoundProfiles[prayerName] = profile;
    await _tasbihStore.savePrayerSoundProfile(prayerName, profile);
    await refreshPrayerData();
  }

  Future<void> setAllPrayerSoundProfiles(String profile) async {
    for (final name in prayerNamesOrdered) {
      prayerSoundProfiles[name] = profile;
      await _tasbihStore.savePrayerSoundProfile(name, profile);
    }
    await refreshPrayerData();
  }

  Future<void> setRespectSilentMode(bool value) async {
    respectSilentMode = value;
    await _tasbihStore.saveRespectSilentMode(value);
    await refreshPrayerData();
  }

  Future<void> setPrayerCalculationMethod(String value) async {
    prayerCalculationMethod = value;
    await _tasbihStore.savePrayerCalculationMethod(value);
    await refreshPrayerData();
  }

  Future<void> setAsarMethod(String value) async {
    asarMethod = value;
    await _tasbihStore.saveAsarMethod(value);
    await refreshPrayerData();
  }

  Future<void> setHighLatitudeRule(String value) async {
    highLatitudeRule = value;
    await _tasbihStore.saveHighLatitudeRule(value);
    await refreshPrayerData();
  }

  Future<void> setManualPrayerAdjustment(String prayerName, int minutes) async {
    manualPrayerAdjustments[prayerName] = minutes.clamp(-30, 30).toInt();
    await _tasbihStore.saveManualPrayerAdjustments(manualPrayerAdjustments);
    await refreshPrayerData();
  }

  Future<void> setAllPrayerNotifications(bool value) async {
    for (final name in prayerNamesOrdered) {
      prayerNotificationToggles[name] = value;
      await _tasbihStore.savePrayerNotificationToggle(name, value);
    }
    await refreshPrayerData();
  }

  Future<void> previewPrayerSound(String prayerName) async {
    final profile = prayerSoundProfiles[prayerName] ?? 'default';
    await _notificationService.showPrayerSoundPreview(
      prayerName: prayerName,
      soundProfile: profile,
      enableVibration: vibrateEnabled,
      respectSilentMode: respectSilentMode,
    );
  }

  Future<void> setTravelModeEnabled(bool value) async {
    travelModeEnabled = value;
    await _tasbihStore.saveTravelModeEnabled(value);
    notifyListeners();
  }

  Future<void> setFastingMondayThursdayEnabled(bool value) async {
    if (fastingMondayThursdayEnabled == value) {
      return;
    }
    fastingMondayThursdayEnabled = value;
    notifyListeners();
    await _tasbihStore.saveFastingMonThuEnabled(value);
    _queueFastingReminderReschedule();
  }

  Future<void> setFastingAyyamulBidhEnabled(bool value) async {
    if (fastingAyyamulBidhEnabled == value) {
      return;
    }
    fastingAyyamulBidhEnabled = value;
    notifyListeners();
    await _tasbihStore.saveFastingAyyamulBidhEnabled(value);
    _queueFastingReminderReschedule();
  }

  Future<void> setTasbihCycleTarget(int value) async {
    final safe = value <= 0 ? 33 : value;
    tasbihCycleTarget = safe;
    await _tasbihStore.saveTasbihCycleTarget(safe);
    notifyListeners();
  }

  Future<void> setTasbihAutoResetDaily(bool value) async {
    tasbihAutoResetDaily = value;
    await _tasbihStore.saveTasbihAutoResetDaily(value);
    if (value) {
      await _ensureTasbihDailyReset(forceWriteDate: true);
    }
    notifyListeners();
  }

  Future<void> setLanguageCode(String value) async {
    languageCode = value == 'en' ? 'en' : 'ms';
    await _tasbihStore.saveLanguageCode(languageCode);
    notifyListeners();
  }

  Future<void> setHijriOffsetDays(int value) async {
    final next = value.clamp(-2, 2);
    if (hijriOffsetDays == next) {
      return;
    }
    hijriOffsetDays = next;
    notifyListeners();
    await _tasbihStore.saveHijriOffsetDays(hijriOffsetDays);
    _queueFastingReminderReschedule();
    await _updateWidgetData();
  }

  Future<void> resetAllManualPrayerAdjustments() async {
    manualPrayerAdjustments = <String, int>{
      for (final name in prayerNamesOrdered) name: 0,
    };
    await _tasbihStore.saveManualPrayerAdjustments(manualPrayerAdjustments);
    await refreshPrayerData();
  }

  String t(String key, {Map<String, String> params = const {}}) {
    return AppLocalizations(languageCode).text(key, params: params);
  }

  String tr(String bm, String en) {
    return isEnglish ? en : bm;
  }

  String displayPrayerName(String prayerName) {
    if (!isEnglish) {
      return prayerName;
    }
    const names = <String, String>{
      'Imsak': 'Imsak',
      'Subuh': 'Fajr',
      'Syuruk': 'Sunrise',
      'Zohor': 'Dhuhr',
      'Asar': 'Asr',
      'Maghrib': 'Maghrib',
      'Isyak': 'Isha',
    };
    return names[prayerName] ?? prayerName;
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
      'respectSilentMode': respectSilentMode,
      'prayerNotificationToggles': prayerNotificationToggles,
      'prayerSoundProfiles': prayerSoundProfiles,
      'prayerCalculationMethod': prayerCalculationMethod,
      'asarMethod': asarMethod,
      'highLatitudeRule': highLatitudeRule,
      'manualPrayerAdjustments': manualPrayerAdjustments,
      'favoriteZones': favoriteZones,
      'recentZones': recentZones,
      'prayerCheckinsByDate': prayerCheckinsByDate,
      'notificationLeadMinutes': notificationLeadMinutes,
      'tasbihCycleTarget': tasbihCycleTarget,
      'tasbihAutoResetDaily': tasbihAutoResetDaily,
      'languageCode': languageCode,
      'hijriOffsetDays': hijriOffsetDays,
      'tasbihLifetimeCount': tasbihLifetimeCount,
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
    fastingMondayThursdayEnabled =
        parsed['fastingMondayThursdayEnabled'] as bool? ??
            fastingMondayThursdayEnabled;
    fastingAyyamulBidhEnabled = parsed['fastingAyyamulBidhEnabled'] as bool? ??
        fastingAyyamulBidhEnabled;
    respectSilentMode =
        parsed['respectSilentMode'] as bool? ?? respectSilentMode;

    final toggles = parsed['prayerNotificationToggles'];
    if (toggles is Map<String, dynamic>) {
      prayerNotificationToggles = toggles.map((k, v) => MapEntry(k, v == true));
    }

    final sounds = parsed['prayerSoundProfiles'];
    if (sounds is Map<String, dynamic>) {
      prayerSoundProfiles = sounds.map(
        (k, v) => MapEntry(k, (v ?? 'default').toString()),
      );
    }
    prayerCalculationMethod =
        parsed['prayerCalculationMethod'] as String? ?? prayerCalculationMethod;
    asarMethod = parsed['asarMethod'] as String? ?? asarMethod;
    highLatitudeRule =
        parsed['highLatitudeRule'] as String? ?? highLatitudeRule;
    final adjustments = parsed['manualPrayerAdjustments'];
    if (adjustments is Map<String, dynamic>) {
      manualPrayerAdjustments = adjustments.map(
        (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
      );
      _normalizeManualAdjustments();
    }

    final fav = parsed['favoriteZones'];
    if (fav is List) {
      favoriteZones = fav.map((e) => e.toString()).toList();
    }
    final rec = parsed['recentZones'];
    if (rec is List) {
      recentZones = rec.map((e) => e.toString()).toList();
    }
    final checkins = parsed['prayerCheckinsByDate'];
    if (checkins is Map<String, dynamic>) {
      prayerCheckinsByDate = checkins.map((key, value) {
        final list = value is List
            ? value.map((item) => item.toString()).toList()
            : <String>[];
        return MapEntry(key, list);
      });
    }
    notificationLeadMinutes =
        (parsed['notificationLeadMinutes'] as num?)?.toInt() ??
            notificationLeadMinutes;
    tasbihCycleTarget =
        (parsed['tasbihCycleTarget'] as num?)?.toInt() ?? tasbihCycleTarget;
    tasbihAutoResetDaily =
        parsed['tasbihAutoResetDaily'] as bool? ?? tasbihAutoResetDaily;
    languageCode = (parsed['languageCode'] as String? ?? languageCode) == 'en'
        ? 'en'
        : 'ms';
    hijriOffsetDays =
        ((parsed['hijriOffsetDays'] as num?)?.toInt() ?? hijriOffsetDays)
            .clamp(-2, 2);
    tasbihLifetimeCount =
        (parsed['tasbihLifetimeCount'] as num?)?.toInt() ?? tasbihLifetimeCount;

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
    await _tasbihStore.saveRespectSilentMode(respectSilentMode);
    await _tasbihStore.savePrayerCalculationMethod(prayerCalculationMethod);
    await _tasbihStore.saveAsarMethod(asarMethod);
    await _tasbihStore.saveHighLatitudeRule(highLatitudeRule);
    await _tasbihStore.saveManualPrayerAdjustments(manualPrayerAdjustments);
    await _tasbihStore.saveFavoriteZones(favoriteZones);
    await _tasbihStore.saveRecentZones(recentZones);
    await _tasbihStore.savePrayerCheckins(prayerCheckinsByDate);
    await _tasbihStore.saveNotificationLeadMinutes(notificationLeadMinutes);
    await _tasbihStore.saveTasbihCycleTarget(tasbihCycleTarget);
    await _tasbihStore.saveTasbihAutoResetDaily(tasbihAutoResetDaily);
    await _tasbihStore.saveLanguageCode(languageCode);
    await _tasbihStore.saveHijriOffsetDays(hijriOffsetDays);
    await _tasbihStore.saveTasbihLifetimeCount(tasbihLifetimeCount);
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
      rows.add(
          '$d,${findTime('Imsak')},${findTime('Subuh')},${findTime('Syuruk')},${findTime('Zohor')},${findTime('Asar')},${findTime('Maghrib')},${findTime('Isyak')}');
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
        b.writeln('UID:${entry.name}-$start@waktusolat');
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
      b.writeln('UID:${entry.name}-$start@waktusolat');
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

  bool isPrayerCompletedToday(String prayerName) {
    return todayPrayerCheckins.contains(prayerName);
  }

  Future<void> togglePrayerCompletedToday(String prayerName) async {
    final key = _dateKey(DateTime.now());
    final current = List<String>.from(prayerCheckinsByDate[key] ?? <String>[]);
    if (current.contains(prayerName)) {
      current.remove(prayerName);
    } else {
      current.add(prayerName);
    }
    prayerCheckinsByDate[key] = current;
    await _tasbihStore.savePrayerCheckins(prayerCheckinsByDate);
    notifyListeners();
  }

  Future<void> markCurrentPrayerAsDone() async {
    final current = _currentPrayerForNow();
    if (current == null) {
      return;
    }
    if (isPrayerCompletedToday(current.name)) {
      return;
    }
    await togglePrayerCompletedToday(current.name);
  }

  List<DailyPrayerTimes> upcomingFastingReminderDates({int limit = 5}) {
    if (limit <= 0) {
      return const <DailyPrayerTimes>[];
    }
    final monthly = monthlyPrayerTimes;
    if (monthly == null) {
      return const <DailyPrayerTimes>[];
    }
    final days = <DailyPrayerTimes>[
      ...monthly.days,
      ...(nextMonthlyPrayerTimes?.days ?? const <DailyPrayerTimes>[]),
    ]..sort((a, b) => a.date.compareTo(b.date));
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final result = <DailyPrayerTimes>[];
    for (final day in days) {
      final current = DateTime(day.date.year, day.date.month, day.date.day);
      if (current.isBefore(start)) {
        continue;
      }
      if (_isFastingTargetDay(day)) {
        result.add(day);
      }
      if (result.length >= limit) {
        break;
      }
    }
    return result;
  }

  String formatHijriWithOffset(
    String? hijriRaw, {
    bool fallbackUnavailable = false,
  }) {
    final parsed = _parseHijriParts(hijriRaw);
    if (parsed == null) {
      return fallbackUnavailable ? t('hijri_unavailable') : '-';
    }
    final adjusted = _applyHijriOffsetToParts(
      day: parsed.$1,
      month: parsed.$2,
      year: parsed.$3,
      offset: hijriOffsetDays,
    );
    return _formatHijriParts(adjusted);
  }

  bool _isDifferentDay(DateTime a, DateTime b) =>
      a.year != b.year || a.month != b.month || a.day != b.day;

  PrayerTimeEntry? _currentPrayerForNow() {
    final entries = dailyPrayerTimes?.entries;
    if (entries == null || entries.isEmpty) {
      return null;
    }
    final now = DateTime.now();
    PrayerTimeEntry? current;
    for (final entry in entries) {
      if (entry.time.isBefore(now) || entry.time.isAtSameMomentAs(now)) {
        current = entry;
      }
    }
    return current;
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (_errorActionCode == 'open_app') {
      return t('error_generic');
    }
    if (text.contains('location') || text.contains('lokasi')) {
      _errorActionCode = 'open_location';
      return t('error_location_unavailable');
    }
    if (text.contains('timeout')) {
      _errorActionCode = 'manual_zone';
      return t('error_slow_connection');
    }
    if (text.contains('tidak tersedia')) {
      _errorActionCode = 'manual_zone';
      return t('error_server_unavailable');
    }
    if (_errorActionCode != 'open_app') {
      _errorActionCode = null;
    }
    return t('error_generic');
  }

  String? get errorActionLabel {
    if (errorMessage == null) {
      return null;
    }
    switch (_errorActionCode) {
      case 'open_location':
        return t('error_action_open_location');
      case 'open_app':
        return t('error_action_open_app');
      case 'manual_zone':
        return t('error_action_manual_zone');
      default:
        return null;
    }
  }

  Future<void> runErrorAction() async {
    final code = _errorActionCode;
    if (code == null) {
      return;
    }
    if (code == 'open_location') {
      await Geolocator.openLocationSettings();
      return;
    }
    if (code == 'open_app') {
      await Geolocator.openAppSettings();
      return;
    }
    if (code == 'manual_zone') {
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

  bool _isFastingTargetDay(DailyPrayerTimes day) {
    final weekday = day.date.weekday;
    final monThu = fastingMondayThursdayEnabled &&
        (weekday == DateTime.monday || weekday == DateTime.thursday);
    final parsed = _parseHijriParts(day.hijriDate);
    final adjusted = parsed == null
        ? null
        : _applyHijriOffsetToParts(
            day: parsed.$1,
            month: parsed.$2,
            year: parsed.$3,
            offset: hijriOffsetDays,
          );
    final hijriDay = adjusted?.$1;
    final hijriMonth = adjusted?.$2;
    final ramadan = hijriMonth == 9;
    final ayyamulBidh = fastingAyyamulBidhEnabled &&
        hijriDay != null &&
        hijriDay >= 13 &&
        hijriDay <= 15;
    return ramadan || monThu || ayyamulBidh;
  }

  String _formatOffset(int value) {
    return value > 0 ? '+$value' : '$value';
  }

  String _formatHijriParts((int, int, int) parts) {
    final day = parts.$1;
    final month = parts.$2;
    final year = parts.$3;
    final monthLabel = _monthNameByLocale(month);
    return '$day $monthLabel ${year}H';
  }

  String _monthNameByLocale(int month) {
    const bm = <String>[
      'Muharam',
      'Safar',
      'Rabiulawal',
      'Rabiulakhir',
      'Jamadilawal',
      'Jamadilakhir',
      'Rejab',
      'Syaaban',
      'Ramadan',
      'Syawal',
      'Zulkaedah',
      'Zulhijjah',
    ];
    const en = <String>[
      'Muharram',
      'Safar',
      'Rabi al-Awwal',
      'Rabi al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      'Shaaban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qadah',
      'Dhu al-Hijjah',
    ];
    final index = (month - 1).clamp(0, 11);
    return isEnglish ? en[index] : bm[index];
  }

  (int, int, int)? _parseHijriParts(String? hijriRaw) {
    final value = hijriRaw?.toLowerCase().trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    final clean = value.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    if (clean.isEmpty) {
      return null;
    }
    final tokens = clean.split(RegExp(r'\s+'));
    int? day;
    int? year;
    int? month;
    for (final token in tokens) {
      final n = int.tryParse(token);
      if (n == null) {
        continue;
      }
      day ??= n;
      if (n >= 1000) {
        year = n;
      }
    }
    for (final token in tokens) {
      final normalized = token.replaceAll(RegExp(r'[^a-z]'), '');
      final mapped = _hijriMonthAliases[normalized];
      if (mapped != null) {
        month = mapped;
        break;
      }
    }
    if (day == null || month == null || year == null) {
      return null;
    }
    return (day, month, year);
  }

  (int, int, int) _applyHijriOffsetToParts({
    required int day,
    required int month,
    required int year,
    required int offset,
  }) {
    var d = day;
    var m = month;
    var y = year;
    if (offset == 0) {
      return (d, m, y);
    }
    d += offset;
    while (d > 30) {
      d -= 30;
      m += 1;
      if (m > 12) {
        m = 1;
        y += 1;
      }
    }
    while (d < 1) {
      d += 30;
      m -= 1;
      if (m < 1) {
        m = 12;
        y -= 1;
      }
    }
    return (d, m, y);
  }

  static const Map<String, int> _hijriMonthAliases = <String, int>{
    'muharam': 1,
    'muharram': 1,
    'safar': 2,
    'rabiulawal': 3,
    'rabiulawwal': 3,
    'rabialawal': 3,
    'rabialawwal': 3,
    'rabiulakhir': 4,
    'rabiulthani': 4,
    'rabiathani': 4,
    'jamadilawal': 5,
    'jamadalawal': 5,
    'jumadaalawwal': 5,
    'jamadilakhir': 6,
    'jamadalthani': 6,
    'jumadaalthani': 6,
    'rejab': 7,
    'rajab': 7,
    'syaaban': 8,
    'shaaban': 8,
    'ramadan': 9,
    'ramadhan': 9,
    'syawal': 10,
    'shawwal': 10,
    'zulkaedah': 11,
    'dhualqadah': 11,
    'zulhijjah': 12,
    'dhualhijjah': 12,
  };

  DailyPrayerTimes _applyManualAdjustmentsToDaily(DailyPrayerTimes source) {
    if (manualPrayerAdjustments.isEmpty ||
        manualPrayerAdjustments.values.every((v) => v == 0)) {
      return source;
    }
    final entries = source.entries.map((entry) {
      final adjust = manualPrayerAdjustments[entry.name] ?? 0;
      if (adjust == 0) {
        return entry;
      }
      return PrayerTimeEntry(
        name: entry.name,
        time: entry.time.add(Duration(minutes: adjust)),
      );
    }).toList(growable: false);
    return DailyPrayerTimes(
      zone: source.zone,
      date: source.date,
      entries: entries,
      hijriDate: source.hijriDate,
    );
  }

  void _normalizeManualAdjustments() {
    final next = <String, int>{};
    for (final name in prayerNamesOrdered) {
      next[name] = (manualPrayerAdjustments[name] ?? 0).clamp(-30, 30).toInt();
    }
    manualPrayerAdjustments = next;
  }

  bool _isCustomCalculationPreferenceEnabled() {
    final methodCustom = prayerCalculationMethod.toUpperCase() != 'JAKIM';
    final asarCustom = !asarMethod.toLowerCase().contains("shafi");
    final highLatCustom =
        highLatitudeRule.toLowerCase() != 'middle of the night';
    return methodCustom || asarCustom || highLatCustom;
  }

  Future<void> _scheduleFastingReminders() async {
    final monthly = monthlyPrayerTimes;
    if (monthly == null) {
      return;
    }
    final days = <DailyPrayerTimes>[
      ...monthly.days,
      ...(nextMonthlyPrayerTimes?.days ?? const <DailyPrayerTimes>[]),
    ];
    try {
      await _notificationService.scheduleFastingReminders(
        monthlyDays: days,
        enableNotification: notifyEnabled,
        enableRamadhanMode: ramadhanMode,
        enableMondayThursday: fastingMondayThursdayEnabled,
        enableAyyamulBidh: fastingAyyamulBidhEnabled,
        enableVibration: vibrateEnabled,
      );
    } catch (_) {
      _pushHealthLog('fasting_schedule_err');
    }
  }

  void _queueFastingReminderReschedule() {
    _fastingRescheduleDebounce?.cancel();
    _fastingRescheduleDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_scheduleFastingReminders());
    });
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
    final nextName =
        next == null ? tr('Tiada', 'None') : displayPrayerName(next.name);
    final nextTimeText = next == null
        ? '--:--'
        : '${next.time.hour.toString().padLeft(2, '0')}:${next.time.minute.toString().padLeft(2, '0')}';
    final locationLabel = activeZone?.location ??
        tr('Lokasi tidak diketahui', 'Unknown location');
    final liveLabel = tr('Langsung', 'Live');
    final current = _currentPrayerForNow();
    final currentName =
        current == null ? tr('Tiada', 'None') : displayPrayerName(current.name);
    final currentTimeText = current == null
        ? '--:--'
        : '${current.time.hour.toString().padLeft(2, '0')}:${current.time.minute.toString().padLeft(2, '0')}';
    final subtitle = next == null
        ? tr('Tiada waktu seterusnya', 'No next prayer')
        : next.name == 'Imsak'
            ? tr('Sebelum Subuh bermula', 'Before Subuh begins')
            : tr(
                'Sehingga ${displayPrayerName(next.name)} bermula',
                'Until ${displayPrayerName(next.name)} begins',
              );
    final remainingCheckIns =
        (todayPrayerTargetCount - todayPrayerCompletedCount).clamp(0, 99);

    final payload = <String, String>{
      'widget_title': tr('Waktu Solat', 'Prayer Times'),
      'widget_subtitle': next == null
          ? tr('Tiada waktu seterusnya', 'No next prayer')
          : '${displayPrayerName(next.name)} ${next.time.hour.toString().padLeft(2, '0')}:${next.time.minute.toString().padLeft(2, '0')}',
      'widget_countdown': _formatWidgetCountdownShort(countdown),
      'widget_tasbih': '$tasbihCount',
    };
    await _saveWidgetPayload(payload);
    await _widgetUpdateService.updateWidgets(
      nextName: nextName,
      nextTime: nextTimeText,
      nextCountdown: _formatWidgetCountdownShort(countdown),
      nextSubtitle: subtitle,
      locationLabel: locationLabel,
      liveLabel: liveLabel,
      todayDone: '$todayPrayerCompletedCount/$todayPrayerTargetCount',
      streakText: '${tasbihStreakDays}h',
      currentName: currentName,
      currentTime: currentTimeText,
      remainingCount: 'Baki check-in: $remainingCheckIns',
      nextPrayerEpoch: next?.time.millisecondsSinceEpoch ?? 0,
    );
  }

  Future<void> _saveWidgetPayload(Map<String, String> data) async {
    final store = await SharedPreferences.getInstance();
    for (final entry in data.entries) {
      await store.setString(entry.key, entry.value);
    }
  }

  String _formatWidgetCountdownShort(Duration? d) {
    if (d == null) {
      return '--j --m';
    }
    final safe = d.isNegative ? Duration.zero : d;
    final h = safe.inHours;
    final m = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${h}j ${m}m';
  }

  Future<void> _addTasbihDaily(int count) async {
    await _ensureTasbihDailyReset();
    final key = _dateKey(DateTime.now());
    tasbihDailyStats[key] = (tasbihDailyStats[key] ?? 0) + count;
    await _tasbihStore.saveTasbihDailyStats(tasbihDailyStats);
  }

  Future<void> _subtractTasbihDaily(int count) async {
    await _ensureTasbihDailyReset();
    final key = _dateKey(DateTime.now());
    final current = tasbihDailyStats[key] ?? 0;
    final next = (current - count).clamp(0, 999999999);
    tasbihDailyStats[key] = next;
    await _tasbihStore.saveTasbihDailyStats(tasbihDailyStats);
  }

  Future<void> _ensureTasbihDailyReset({bool forceWriteDate = false}) async {
    final todayKey = _dateKey(DateTime.now());
    final lastReset = await _tasbihStore.loadTasbihLastResetDate();
    if (tasbihAutoResetDaily &&
        lastReset != null &&
        lastReset != todayKey &&
        tasbihCount > 0) {
      tasbihCount = 0;
      await _tasbihStore.saveCount(0);
    }
    if (forceWriteDate || lastReset != todayKey) {
      await _tasbihStore.saveTasbihLastResetDate(todayKey);
    }
  }

  void _scheduleAutoRetry() {
    if (_retryAttempt >= 3) {
      return;
    }
    _retryTimer?.cancel();
    _retryAttempt += 1;
    final delay = Duration(seconds: 20 * _retryAttempt);
    _retryTimer = Timer(delay, () {
      unawaited(refreshPrayerData());
    });
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
    _retryTimer?.cancel();
    _fastingRescheduleDebounce?.cancel();
    _notificationResponseSub?.cancel();
    _notificationService.dispose();
    super.dispose();
  }
}
