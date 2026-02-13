import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_models.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> schedulePrayerNotifications({
    required List<PrayerTimeEntry> prayers,
    required bool enableNotification,
    required bool enableVibration,
  }) async {
    await initialize();
    await _plugin.cancelAll();

    if (!enableNotification) {
      return;
    }

    final now = DateTime.now();
    var id = 100;

    for (final prayer in prayers) {
      if (prayer.time.isBefore(now)) {
        continue;
      }

      final scheduleDate = tz.TZDateTime.from(prayer.time, tz.local);

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
}
