class PrayerZone {
  const PrayerZone({
    required this.code,
    required this.state,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  final String code;
  final String state;
  final String location;
  final double latitude;
  final double longitude;

  String get label => '$code - $location, $state';

  factory PrayerZone.fromJson(Map<String, dynamic> json) {
    return PrayerZone(
      code: (json['code'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      latitude: double.tryParse((json['latitude'] ?? '').toString()) ?? 0,
      longitude: double.tryParse((json['longitude'] ?? '').toString()) ?? 0,
    );
  }
}

class PrayerTimeEntry {
  const PrayerTimeEntry({required this.name, required this.time});

  final String name;
  final DateTime time;
}

class DailyPrayerTimes {
  const DailyPrayerTimes({
    required this.zone,
    required this.date,
    required this.entries,
  });

  final String zone;
  final DateTime date;
  final List<PrayerTimeEntry> entries;
}

class MonthlyPrayerTimes {
  const MonthlyPrayerTimes({
    required this.zone,
    required this.month,
    required this.days,
  });

  final String zone;
  final DateTime month;
  final List<DailyPrayerTimes> days;
}
