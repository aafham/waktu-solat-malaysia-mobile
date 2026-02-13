import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_models.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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

    await _plugin.initialize(settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final macosPlugin = _plugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();

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

      final scheduleDate = tz.TZDateTime.from(prayer.time, tz.local);
      final soundProfile = prayerSoundProfiles?[prayer.name] ?? 'default';
      final isSilent = soundProfile == 'silent';
      final rawResource = soundProfile.startsWith('raw:')
          ? soundProfile.substring(4)
          : null;

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
}
