import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import '../models/prayer_models.dart';

class PrayerService {
  static const String _primaryApiBaseUrl = 'https://solat.my/api';
  static const String _legacyApiBaseUrl = 'https://api.solat.my/v2';

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
    final endpoints = <Uri>[
      Uri.parse('$_primaryApiBaseUrl/locations'),
      Uri.parse('$_legacyApiBaseUrl/locations'),
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http
            .get(endpoint)
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) {
          continue;
        }

        final body = jsonDecode(response.body);
        final parsed = _parseZones(body);
        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (_) {
        // Try next endpoint.
      }
    }

    return _fallbackZones;
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
    final endpoints = <Uri>[
      Uri.parse('$_primaryApiBaseUrl/daily/$zoneCode'),
      Uri.parse('$_legacyApiBaseUrl/times/$zoneCode'),
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http
            .get(endpoint)
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) {
          continue;
        }

        return _parseDailyPrayerTimes(zoneCode, response.body);
      } catch (_) {
        // Try next endpoint.
      }
    }

    throw Exception('Gagal ambil data waktu solat untuk zon $zoneCode.');
  }

  List<PrayerZone> _parseZones(dynamic body) {
    final List<dynamic> rawZones;
    if (body is List<dynamic>) {
      rawZones = body;
    } else if (body is Map<String, dynamic>) {
      rawZones = body['data'] as List<dynamic>? ?? <dynamic>[];
    } else {
      return <PrayerZone>[];
    }

    final seenCodes = <String>{};
    final parsed = <PrayerZone>[];

    for (final raw in rawZones) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final zone = PrayerZone.fromJson(raw);
      if (zone.code.isEmpty || seenCodes.contains(zone.code)) {
        continue;
      }
      seenCodes.add(zone.code);
      parsed.add(zone);
    }

    parsed.sort((a, b) => a.code.compareTo(b.code));
    return parsed;
  }

  DailyPrayerTimes _parseDailyPrayerTimes(String zoneCode, String bodyText) {
    final body = jsonDecode(bodyText);
    if (body is! Map<String, dynamic>) {
      throw Exception('Data waktu solat tidak sah.');
    }

    Map<String, dynamic>? data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      final prayerTime = body['prayerTime'] as List<dynamic>? ?? <dynamic>[];
      if (prayerTime.isNotEmpty && prayerTime.first is Map<String, dynamic>) {
        data = prayerTime.first as Map<String, dynamic>;
      }
    }

    if (data == null) {
      throw Exception('Data waktu solat tidak sah.');
    }

    final date = _parseDate((data['date'] ?? '').toString());

    DateTime parseTime(List<String> keys, String label) {
      for (final key in keys) {
        final value = (data?[key] ?? '').toString().trim();
        if (value.isEmpty) {
          continue;
        }
        final parts = value.split(':');
        if (parts.length < 2) {
          continue;
        }

        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) {
          continue;
        }

        return DateTime(date.year, date.month, date.day, hour, minute);
      }

      throw Exception('Format masa tidak sah untuk $label.');
    }

    return DailyPrayerTimes(
      zone: zoneCode,
      date: date,
      entries: <PrayerTimeEntry>[
        PrayerTimeEntry(name: 'Imsak', time: parseTime(<String>['imsak'], 'imsak')),
        PrayerTimeEntry(name: 'Subuh', time: parseTime(<String>['fajr', 'subuh'], 'subuh')),
        PrayerTimeEntry(name: 'Syuruk', time: parseTime(<String>['syuruk', 'sunrise'], 'syuruk')),
        PrayerTimeEntry(name: 'Zohor', time: parseTime(<String>['dhuhr', 'zohor'], 'zohor')),
        PrayerTimeEntry(name: 'Asar', time: parseTime(<String>['asr'], 'asar')),
        PrayerTimeEntry(name: 'Maghrib', time: parseTime(<String>['maghrib'], 'maghrib')),
        PrayerTimeEntry(name: 'Isyak', time: parseTime(<String>['isha', 'isyak'], 'isyak')),
      ],
    );
  }

  DateTime _parseDate(String value) {
    final trimmed = value.trim();
    final parsedIso = DateTime.tryParse(trimmed);
    if (parsedIso != null) {
      return parsedIso;
    }

    final parts = trimmed.split('-');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = _monthFromAbbreviation(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime.now();
  }

  int? _monthFromAbbreviation(String value) {
    switch (value.toLowerCase()) {
      case 'jan':
        return 1;
      case 'feb':
        return 2;
      case 'mar':
        return 3;
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'jun':
        return 6;
      case 'jul':
        return 7;
      case 'aug':
        return 8;
      case 'sep':
        return 9;
      case 'oct':
        return 10;
      case 'nov':
        return 11;
      case 'dec':
        return 12;
      default:
        return null;
    }
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
