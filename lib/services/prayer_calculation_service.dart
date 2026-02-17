import 'dart:math';

import '../models/prayer_models.dart';

class PrayerCalculationService {
  const PrayerCalculationService();

  DailyPrayerTimes calculateDaily({
    required PrayerZone zone,
    required DateTime date,
    required String calculationMethod,
    required String asarMethod,
    required String highLatitudeRule,
  }) {
    final localDate = DateTime(date.year, date.month, date.day);
    const tzOffsetHours = 8.0;
    final lat = zone.latitude;
    final lng = zone.longitude;

    final dayOfYear = _dayOfYear(localDate);
    final decl = _solarDeclination(dayOfYear);
    final eq = _equationOfTime(dayOfYear);
    final noon = (720 - (4 * lng) - eq + (tzOffsetHours * 60)) / 60.0;

    final sunriseHa = _hourAngle(lat, decl, 90.833);
    final sunrise = noon - (sunriseHa / 15.0);
    final sunset = noon + (sunriseHa / 15.0);

    final method = _methodAngles(calculationMethod);
    final fajrHa = _hourAngle(lat, decl, 90 + method.fajrAngle);
    final ishaHa = _hourAngle(lat, decl, 90 + method.ishaAngle);

    var fajr = noon - (fajrHa / 15.0);
    var isha = noon + (ishaHa / 15.0);

    final asrFactor = asarMethod.toLowerCase().contains('hanafi') ? 2.0 : 1.0;
    final asrHa = _asrHourAngle(lat, decl, asrFactor);
    final asr = noon + (asrHa / 15.0);

    final nightDuration = _nightHours(sunset, sunrise);
    final fajrLimit =
        _nightPortion(highLatitudeRule, method.fajrAngle) * nightDuration;
    final ishaLimit =
        _nightPortion(highLatitudeRule, method.ishaAngle) * nightDuration;
    final sunriseSafe = _normalizeHour(sunrise);
    final sunsetSafe = _normalizeHour(sunset);

    final fajrFloor = _normalizeHour(sunriseSafe - fajrLimit);
    final ishaCap = _normalizeHour(sunsetSafe + ishaLimit);
    fajr = _adjustHighLatPreDawn(fajr, sunriseSafe, fajrFloor);
    isha = _adjustHighLatPostSunset(isha, sunsetSafe, ishaCap);

    final imsak = _normalizeHour(fajr - (10.0 / 60.0));
    final syuruk = sunriseSafe;
    final zohor = _normalizeHour(noon + (2.0 / 60.0));
    final maghrib = sunsetSafe;

    return DailyPrayerTimes(
      zone: zone.code,
      date: localDate,
      entries: <PrayerTimeEntry>[
        PrayerTimeEntry(name: 'Imsak', time: _toDateTime(localDate, imsak)),
        PrayerTimeEntry(name: 'Subuh', time: _toDateTime(localDate, fajr)),
        PrayerTimeEntry(name: 'Syuruk', time: _toDateTime(localDate, syuruk)),
        PrayerTimeEntry(name: 'Zohor', time: _toDateTime(localDate, zohor)),
        PrayerTimeEntry(name: 'Asar', time: _toDateTime(localDate, asr)),
        PrayerTimeEntry(name: 'Maghrib', time: _toDateTime(localDate, maghrib)),
        PrayerTimeEntry(name: 'Isyak', time: _toDateTime(localDate, isha)),
      ],
    );
  }

  _MethodAngles _methodAngles(String method) {
    switch (method.toUpperCase()) {
      case 'MWL':
        return const _MethodAngles(fajrAngle: 18.0, ishaAngle: 17.0);
      case 'ISNA':
        return const _MethodAngles(fajrAngle: 15.0, ishaAngle: 15.0);
      case 'UMM AL-QURA':
        return const _MethodAngles(fajrAngle: 18.5, ishaAngle: 18.5);
      case 'EGYPTIAN':
        return const _MethodAngles(fajrAngle: 19.5, ishaAngle: 17.5);
      case 'KARACHI':
        return const _MethodAngles(fajrAngle: 18.0, ishaAngle: 18.0);
      case 'JAKIM':
      default:
        return const _MethodAngles(fajrAngle: 20.0, ishaAngle: 18.0);
    }
  }

  double _nightPortion(String rule, double angle) {
    switch (rule.toLowerCase()) {
      case 'one seventh':
        return 1.0 / 7.0;
      case 'twilight angle':
        return angle / 60.0;
      case 'middle of the night':
      default:
        return 0.5;
    }
  }

  int _dayOfYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    return date.difference(start).inDays + 1;
  }

  double _equationOfTime(int n) {
    final b = _degToRad((360.0 / 365.0) * (n - 81));
    return 9.87 * sin(2 * b) - 7.53 * cos(b) - 1.5 * sin(b);
  }

  double _solarDeclination(int n) {
    return 23.45 * sin(_degToRad((360.0 / 365.0) * (284 + n)));
  }

  double _hourAngle(double latDeg, double declDeg, double zenithDeg) {
    final lat = _degToRad(latDeg);
    final decl = _degToRad(declDeg);
    final zenith = _degToRad(zenithDeg);
    final cosH =
        ((cos(zenith) - (sin(lat) * sin(decl))) / (cos(lat) * cos(decl)))
            .clamp(-1.0, 1.0);
    return _radToDeg(acos(cosH));
  }

  double _asrHourAngle(double latDeg, double declDeg, double factor) {
    final lat = _degToRad(latDeg);
    final decl = _degToRad(declDeg);
    final angle = -atan(1.0 / (factor + tan((lat - decl).abs())));
    final cosH =
        ((sin(angle) - (sin(lat) * sin(decl))) / (cos(lat) * cos(decl)))
            .clamp(-1.0, 1.0);
    return _radToDeg(acos(cosH));
  }

  double _nightHours(double sunset, double sunrise) {
    final ss = _normalizeHour(sunset);
    final sr = _normalizeHour(sunrise);
    if (ss <= sr) {
      return sr - ss + 24.0;
    }
    return (24.0 - ss) + sr;
  }

  double _adjustHighLatPreDawn(double fajr, double sunrise, double floor) {
    final f = _normalizeHour(fajr);
    if (_hourDiff(f, sunrise) > _hourDiff(floor, sunrise)) {
      return floor;
    }
    return f;
  }

  double _adjustHighLatPostSunset(double isha, double sunset, double cap) {
    final i = _normalizeHour(isha);
    if (_hourDiff(sunset, i) > _hourDiff(sunset, cap)) {
      return cap;
    }
    return i;
  }

  double _hourDiff(double from, double to) {
    final f = _normalizeHour(from);
    final t = _normalizeHour(to);
    if (t >= f) {
      return t - f;
    }
    return (24.0 - f) + t;
  }

  DateTime _toDateTime(DateTime date, double hour) {
    final h = _normalizeHour(hour);
    final wholeHour = h.floor();
    final minuteValue = ((h - wholeHour) * 60).round();
    final minute = minuteValue % 60;
    final carry = minuteValue ~/ 60;
    final finalHour = (wholeHour + carry) % 24;
    return DateTime(date.year, date.month, date.day, finalHour, minute);
  }

  double _normalizeHour(double hour) {
    var h = hour % 24.0;
    if (h < 0) {
      h += 24.0;
    }
    return h;
  }

  double _degToRad(double deg) => deg * pi / 180.0;
  double _radToDeg(double rad) => rad * 180.0 / pi;
}

class _MethodAngles {
  const _MethodAngles({required this.fajrAngle, required this.ishaAngle});

  final double fajrAngle;
  final double ishaAngle;
}
