import 'package:flutter_test/flutter_test.dart';
import 'package:waktu_solat_malaysia_mobile/services/prayer_service.dart';

void main() {
  group('PrayerService parser', () {
    final service = PrayerService();

    test('parse daily response from solat.my format', () {
      const body = '''
{
  "prayerTime": [
    {
      "date": "14-Feb-2026",
      "imsak": "05:12:00",
      "fajr": "05:22:00",
      "syuruk": "06:32:00",
      "dhuhr": "12:32:00",
      "asr": "15:52:00",
      "maghrib": "18:29:00",
      "isha": "19:40:00"
    }
  ]
}
''';

      final parsed = service.parseDailyPrayerTimesFromBody('SBH07', body);
      expect(parsed.zone, 'SBH07');
      expect(parsed.entries.length, 7);
      expect(parsed.entries.first.name, 'Imsak');
      expect(parsed.entries[1].name, 'Subuh');
      expect(parsed.entries[1].time.hour, 5);
      expect(parsed.entries[1].time.minute, 22);
    });

    test('parse locations response from array format', () {
      const body = '''
[
  {"state":"Sabah","code":"SBH07","location":"Kota Kinabalu","latitude":"5.980408","longitude":"116.073457"},
  {"state":"Sabah","code":"SBH07","location":"Papar","latitude":"5.734628","longitude":"115.931851"},
  {"state":"Selangor","code":"SGR01","location":"Gombak","latitude":"3.14","longitude":"101.69"}
]
''';
      final zones = service.parseZonesFromBody(body);
      expect(zones.length, 2);
      expect(zones.first.code, 'SBH07');
      expect(zones.last.code, 'SGR01');
    });

    test('parse monthly response', () {
      const body = '''
{
  "prayerTime": [
    {
      "date": "01-Feb-2026",
      "imsak": "05:12:00",
      "fajr": "05:22:00",
      "syuruk": "06:32:00",
      "dhuhr": "12:32:00",
      "asr": "15:52:00",
      "maghrib": "18:29:00",
      "isha": "19:40:00"
    },
    {
      "date": "02-Feb-2026",
      "imsak": "05:12:00",
      "fajr": "05:22:00",
      "syuruk": "06:32:00",
      "dhuhr": "12:32:00",
      "asr": "15:52:00",
      "maghrib": "18:29:00",
      "isha": "19:40:00"
    }
  ]
}
''';
      final parsed =
          service.parseMonthlyPrayerTimesFromBody('SBH07', DateTime(2026, 2), body);
      expect(parsed.days.length, 2);
      expect(parsed.month.month, 2);
    });
  });
}
