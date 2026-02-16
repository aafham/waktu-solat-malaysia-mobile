import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_models.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationResponse> _responseController =
      StreamController<NotificationResponse>.broadcast();

  bool _initialized = false;
  bool _permissionGranted = true;
  Stream<NotificationResponse> get responses => _responseController.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        _responseController.add(response);
        if (response.actionId == 'snooze_5') {
          final prayerName = response.payload ?? 'Waktu Solat';
          await scheduleSnoozeReminder(
            prayerName: prayerName,
            minutes: 5,
            enableVibration: true,
          );
        }
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final macosPlugin = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    final androidAllowed =
        await androidPlugin?.requestNotificationsPermission() ?? true;
    final iosAllowed = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
    final macosAllowed = await macosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
    _permissionGranted = androidAllowed && iosAllowed && macosAllowed;

    _initialized = true;
  }

  Future<void> schedulePrayerNotifications({
    required List<PrayerTimeEntry> prayers,
    required bool enableNotification,
    required bool enableVibration,
    Set<String>? enabledPrayerNames,
    Map<String, String>? prayerSoundProfiles,
    int leadMinutes = 0,
  }) async {
    await initialize();
    for (var id = 100; id < 220; id++) {
      await _plugin.cancel(id);
    }
    await _plugin.cancel(9999);

    if (!enableNotification) {
      return;
    }
    if (!_permissionGranted) {
      return;
    }

    final now = DateTime.now();
    var id = 100;

    for (final prayer in prayers) {
      if (enabledPrayerNames != null &&
          !enabledPrayerNames.contains(prayer.name)) {
        continue;
      }

      final adjustedTime = prayer.time.subtract(Duration(minutes: leadMinutes));
      if (adjustedTime.isBefore(now)) {
        continue;
      }

      final scheduleDate = tz.TZDateTime.from(adjustedTime, tz.local);
      final soundProfile = prayerSoundProfiles?[prayer.name] ?? 'default';
      final isSilent = soundProfile == 'silent';
      final rawResource =
          soundProfile.startsWith('raw:') ? soundProfile.substring(4) : null;
      final title = leadMinutes > 0
          ? '${prayer.name} dalam $leadMinutes minit'
          : 'Masuk Waktu ${prayer.name}';
      final body = leadMinutes > 0
          ? 'Bersedia untuk ${prayer.name}.'
          : 'Sudah masuk waktu ${prayer.name}.';

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_times_${prayer.name.toLowerCase()}',
          'Waktu Solat ${prayer.name}',
          channelDescription: 'Notifikasi waktu solat harian',
          importance: Importance.max,
          priority: Priority.high,
          playSound: !isSilent,
          sound: rawResource == null
              ? null
              : RawResourceAndroidNotificationSound(rawResource),
          enableVibration: enableVibration,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'snooze_5',
              'Tunda 5 minit',
              showsUserInterface: false,
            ),
            const AndroidNotificationAction(
              'done',
              'Selesai',
              cancelNotification: true,
            ),
          ],
        ),
      );

      await _safeZonedSchedule(
        id: id++,
        title: title,
        body: body,
        scheduleDate: scheduleDate,
        details: details,
        payload: prayer.name,
      );
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return true;
    }
    try {
      final result = await androidPlugin.canScheduleExactNotifications();
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> scheduleSnoozeReminder({
    required String prayerName,
    required int minutes,
    required bool enableVibration,
  }) async {
    await initialize();
    final scheduleDate =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_snooze',
        'Snooze Waktu Solat',
        channelDescription: 'Peringatan snooze waktu solat',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: enableVibration,
      ),
    );

    await _safeZonedSchedule(
      id: 9999,
      title: 'Peringatan $prayerName',
      body: 'Ini peringatan snooze $minutes minit untuk $prayerName.',
      scheduleDate: scheduleDate,
      details: details,
      payload: prayerName,
    );
  }

  Future<void> showPrayerSoundPreview({
    required String prayerName,
    required String soundProfile,
    required bool enableVibration,
  }) async {
    await initialize();
    final isSilent = soundProfile == 'silent';
    final rawResource =
        soundProfile.startsWith('raw:') ? soundProfile.substring(4) : null;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'preview_${prayerName.toLowerCase()}',
        'Pratonton Bunyi $prayerName',
        channelDescription: 'Pratonton bunyi notifikasi',
        importance: Importance.high,
        priority: Priority.high,
        playSound: !isSilent,
        sound: rawResource == null
            ? null
            : RawResourceAndroidNotificationSound(rawResource),
        enableVibration: enableVibration,
      ),
    );

    await _plugin.show(
      8800 + prayerName.hashCode.abs().remainder(500),
      'Pratonton $prayerName',
      isSilent
          ? 'Mod senyap dipilih untuk $prayerName.'
          : 'Ini contoh bunyi notifikasi untuk $prayerName.',
      details,
      payload: prayerName,
    );
  }

  Future<void> scheduleFastingReminders({
    required List<DailyPrayerTimes> monthlyDays,
    required bool enableNotification,
    required bool enableRamadhanMode,
    required bool enableMondayThursday,
    required bool enableAyyamulBidh,
    required bool enableVibration,
  }) async {
    await initialize();
    if (!_permissionGranted) {
      return;
    }

    await _plugin.cancel(21001);
    for (var i = 0; i < 80; i++) {
      await _plugin.cancel(21100 + i);
      await _plugin.cancel(21200 + i);
    }

    if (!enableNotification ||
        (!enableRamadhanMode && !enableMondayThursday && !enableAyyamulBidh)) {
      return;
    }

    final now = DateTime.now();
    var idNight = 21100;
    var idImsak = 21200;
    for (final day in monthlyDays) {
      if (day.date.isBefore(DateTime(now.year, now.month, now.day))) {
        continue;
      }
      final shouldNotify = _isFastingTargetDay(
        day,
        enableRamadhanMode: enableRamadhanMode,
        enableMondayThursday: enableMondayThursday,
        enableAyyamulBidh: enableAyyamulBidh,
      );
      if (!shouldNotify) {
        continue;
      }
      final imsakEntry = day.entries.where((e) => e.name == 'Imsak');
      if (imsakEntry.isEmpty) {
        continue;
      }
      final imsak = imsakEntry.first.time;
      final nightBefore = imsak.subtract(const Duration(hours: 9));
      final preImsak = imsak.subtract(const Duration(minutes: 30));
      if (nightBefore.isAfter(now)) {
        await _safeZonedSchedule(
          id: idNight++,
          title: 'Niat Puasa Esok',
          body: _nightReminderMessage(day),
          scheduleDate: tz.TZDateTime.from(nightBefore, tz.local),
          details: NotificationDetails(
            android: AndroidNotificationDetails(
              'fasting_night',
              'Peringatan Puasa',
              channelDescription: 'Peringatan niat puasa malam',
              importance: Importance.high,
              priority: Priority.high,
              enableVibration: enableVibration,
            ),
          ),
        );
      }
      if (preImsak.isAfter(now)) {
        await _safeZonedSchedule(
          id: idImsak++,
          title: 'Sahur Hampir Tamat',
          body: '30 minit lagi menuju Imsak.',
          scheduleDate: tz.TZDateTime.from(preImsak, tz.local),
          details: NotificationDetails(
            android: AndroidNotificationDetails(
              'fasting_imsak',
              'Peringatan Sahur',
              channelDescription: 'Peringatan hampir imsak',
              importance: Importance.high,
              priority: Priority.high,
              enableVibration: enableVibration,
            ),
          ),
        );
      }
    }
  }

  bool _isFastingTargetDay(
    DailyPrayerTimes day, {
    required bool enableRamadhanMode,
    required bool enableMondayThursday,
    required bool enableAyyamulBidh,
  }) {
    final weekday = day.date.weekday;
    final monThu = enableMondayThursday &&
        (weekday == DateTime.monday || weekday == DateTime.thursday);
    final hijriDay = _extractHijriDay(day.hijriDate);
    final hijriMonth = _extractHijriMonth(day.hijriDate);
    final ramadhan = enableRamadhanMode && hijriMonth == 9;
    final ayyamulBidh = enableAyyamulBidh &&
        hijriDay != null &&
        hijriDay >= 13 &&
        hijriDay <= 15;
    return ramadhan || monThu || ayyamulBidh;
  }

  int? _extractHijriDay(String? hijri) {
    if (hijri == null || hijri.trim().isEmpty) {
      return null;
    }
    final first = hijri.trim().split(' ').first;
    return int.tryParse(first);
  }

  int? _extractHijriMonth(String? hijri) {
    if (hijri == null || hijri.trim().isEmpty) {
      return null;
    }
    final tokens = hijri.trim().split(RegExp(r'\s+'));
    if (tokens.length < 2) {
      return null;
    }
    final monthToken = tokens[1].toLowerCase();
    const monthMap = <String, int>{
      'muharam': 1,
      'safar': 2,
      'rabiulawal': 3,
      'rabiulakhir': 4,
      'jamadilawal': 5,
      'jamadilakhir': 6,
      'rejab': 7,
      'syaaban': 8,
      'ramadan': 9,
      'syawal': 10,
      'zulkaedah': 11,
      'zulhijjah': 12,
    };
    return monthMap[monthToken];
  }

  String _nightReminderMessage(DailyPrayerTimes day) {
    final month = _extractHijriMonth(day.hijriDate);
    if (month == 9) {
      return 'Esok hari puasa Ramadan. Bersedia untuk sahur.';
    }
    return 'Esok hari puasa sunat. Bersedia untuk sahur.';
  }

  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduleDate,
    required NotificationDetails details,
    String? payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduleDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return;
    } on PlatformException catch (e) {
      final message = '${e.code} ${e.message}'.toLowerCase();
      final exactNotAllowed = message.contains('exact_alarms_not_permitted') ||
          message.contains('exact alarms are not permitted');
      if (!exactNotAllowed) {
        rethrow;
      }
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduleDate,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void dispose() {
    _responseController.close();
  }
}
