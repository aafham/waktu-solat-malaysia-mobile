import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';

import '../models/prayer_models.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationResponse> _responsesController =
      StreamController<NotificationResponse>.broadcast();

  bool _initialized = false;
  bool _permissionGranted = true;

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
      onDidReceiveNotificationResponse: (response) {
        _responsesController.add(response);
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidAllowed =
        await androidPlugin?.requestNotificationsPermission() ?? true;
    const darwinAllowed = true;
    _permissionGranted = androidAllowed && darwinAllowed;

    _initialized = true;
  }

  Future<void> schedulePrayerNotifications({
    required List<PrayerTimeEntry> prayers,
    required bool enableNotification,
    required bool enableVibration,
    int leadMinutes = 0,
    Set<String>? enabledPrayerNames,
    Map<String, String>? prayerSoundProfiles,
  }) async {
    await initialize();
    await _plugin.cancelAll();

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

      if (prayer.time.isBefore(now)) {
        continue;
      }

      final adjustedTime = prayer.time.subtract(Duration(minutes: leadMinutes));
      if (adjustedTime.isBefore(now)) {
        continue;
      }
      final scheduleDate = tz.TZDateTime.from(adjustedTime, tz.local);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_times',
          'Waktu Solat',
          channelDescription: 'Notifikasi waktu solat harian',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: enableVibration,
        ),
      );

      await _plugin.zonedSchedule(
        id++,
        'Masuk Waktu ${prayer.name}',
        'Sudah masuk waktu ${prayer.name}.',
        scheduleDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
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

    await _plugin.zonedSchedule(
      9999,
      'Peringatan $prayerName',
      'Ini peringatan snooze $minutes minit untuk $prayerName.',
      scheduleDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Stream<NotificationResponse> get responses => _responsesController.stream;

  Future<bool> canScheduleExactAlarms() async {
    await initialize();
    return true;
  }

  Future<void> showPrayerSoundPreview({
    required String prayerName,
    required String soundProfile,
    required bool enableVibration,
  }) async {
    await initialize();
    await _plugin.show(
      12001,
      'Ujian bunyi $prayerName',
      'Profil bunyi: $soundProfile',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_preview',
          'Ujian Bunyi Solat',
          channelDescription: 'Pratonton bunyi notifikasi waktu solat',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: enableVibration,
        ),
      ),
    );
  }

  Future<void> scheduleFastingReminders({
    required List<DailyPrayerTimes> monthlyDays,
    required bool enableNotification,
    required bool enableMondayThursday,
    required bool enableAyyamulBidh,
    required bool enableVibration,
  }) async {
    await initialize();
    if (!enableNotification) {
      return;
    }
    // Placeholder: fasting reminders can be implemented with dedicated channels later.
  }

  void dispose() {
    _responsesController.close();
  }
}
