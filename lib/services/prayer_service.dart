import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import '../models/prayer_models.dart';

class PrayerService {
  static final List<PrayerZone> _fallbackZones = <PrayerZone>[
    const PrayerZone(code: 'JHR01', state: 'Johor', location: 'Pulau Aur', latitude: 2.45, longitude: 104.52),
    const PrayerZone(code: 'KDH01', state: 'Kedah', location: 'Kota Setar', latitude: 6.12, longitude: 100.37),
    const PrayerZone(code: 'KTN01', state: 'Kelantan', location: 'Kota Bharu', latitude: 6.13, longitude: 102.24),
    const PrayerZone(code: 'MLK01', state: 'Melaka', location: 'Bandar Melaka', latitude: 2.19, longitude: 102.25),
    const PrayerZone(code: 'NGS01', state: 'Negeri Sembilan', location: 'Tampin', latitude: 2.47, longitude: 102.23),
    const PrayerZone(code: 'PHG02', state: 'Pahang', location: 'Kuantan', latitude: 3.81, longitude: 103.33),
    const PrayerZone(code: 'PRK02', state: 'Perak', location: 'Ipoh', latitude: 4.60, longitude: 101.09),
    const PrayerZone(code: 'PLS01', state: 'Perlis', location: 'Kangar', latitude: 6.44, longitude: 100.20),
    const PrayerZone(code: 'PNG01', state: 'Pulau Pinang', location: 'Balik Pulau', latitude: 5.31, longitude: 100.24),
    const PrayerZone(code: 'SBH07', state: 'Sabah', location: 'Kota Kinabalu', latitude: 5.98, longitude: 116.07),
    const PrayerZone(code: 'SWK08', state: 'Sarawak', location: 'Kuching', latitude: 1.55, longitude: 110.34),
    const PrayerZone(code: 'SGR01', state: 'Selangor', location: 'Gombak, Petaling, Sepang', latitude: 3.14, longitude: 101.69),
    const PrayerZone(code: 'TRG01', state: 'Terengganu', location: 'Kuala Terengganu', latitude: 5.33, longitude: 103.14),
    const PrayerZone(code: 'WLY01', state: 'Wilayah Persekutuan', location: 'Kuala Lumpur, Putrajaya', latitude: 3.15, longitude: 101.71),
    const PrayerZone(code: 'WLY02', state: 'Wilayah Persekutuan', location: 'Labuan', latitude: 5.28, longitude: 115.24),
  ];

  Future<List<PrayerZone>> fetchZones() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.solat.my/v2/locations'))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        return _fallbackZones;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (body['data'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PrayerZone.fromJson)
          .where((zone) => zone.code.isNotEmpty)
          .toList();

      if (data.isEmpty) {
        return _fallbackZones;
      }

      data.sort((a, b) => a.code.compareTo(b.code));
      return data;
    } catch (_) {
      return _fallbackZones;
    }
  }

  PrayerZone nearestZone({
    required double latitude,
    required double longitude,
    required List<PrayerZone> zones,
  }) {
    final source = zones.isEmpty ? _fallbackZones : zones;
    PrayerZone best = source.first;
    var bestDistance = _distance(latitude, longitude, best.latitude, best.longitude);

    for (final zone in source.skip(1)) {
      final distance =
          _distance(latitude, longitude, zone.latitude, zone.longitude);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = zone;
      }
    }

    return best;
  }

  Future<DailyPrayerTimes> fetchDailyPrayerTimes(String zoneCode) async {
    final response = await http
        .get(Uri.parse('https://api.solat.my/v2/times/$zoneCode'))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Gagal ambil data waktu solat untuk zon $zoneCode.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Data waktu solat tidak sah.');
    }

    final date = DateTime.tryParse((data['date'] ?? '').toString()) ?? DateTime.now();

    DateTime parseTime(String key) {
      final value = (data[key] ?? '').toString().trim();
      final parts = value.split(':');
      if (parts.length < 2) {
        throw Exception('Format masa tidak sah untuk $key.');
      }
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    return DailyPrayerTimes(
      zone: zoneCode,
      date: date,
      entries: <PrayerTimeEntry>[
        PrayerTimeEntry(name: 'Imsak', time: parseTime('imsak')),
        PrayerTimeEntry(name: 'Subuh', time: parseTime('fajr')),
        PrayerTimeEntry(name: 'Syuruk', time: parseTime('syuruk')),
        PrayerTimeEntry(name: 'Zohor', time: parseTime('dhuhr')),
        PrayerTimeEntry(name: 'Asar', time: parseTime('asr')),
        PrayerTimeEntry(name: 'Maghrib', time: parseTime('maghrib')),
        PrayerTimeEntry(name: 'Isyak', time: parseTime('isha')),
      ],
    );
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}
