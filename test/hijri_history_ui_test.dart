import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:waktu_solat_malaysia_mobile/features/home/history_page.dart';
import 'package:waktu_solat_malaysia_mobile/features/home/home_page.dart';
import 'package:waktu_solat_malaysia_mobile/features/settings/hijri_offset_setting.dart';
import 'package:waktu_solat_malaysia_mobile/models/prayer_models.dart';
import 'package:waktu_solat_malaysia_mobile/services/location_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/notification_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/prayer_calculation_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/prayer_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/qibla_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/tasbih_store.dart';
import 'package:waktu_solat_malaysia_mobile/state/app_controller.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ms_MY');
    await initializeDateFormatting('en_US');
  });

  group('Hijri and history UI', () {
    late _UiTestController controller;

    setUp(() {
      controller = _UiTestController();
      controller.languageCode = 'en';
      final now = DateTime.now();
      controller.dailyPrayerTimes = DailyPrayerTimes(
        zone: 'WLY01',
        date: now,
        hijriDate: '28 Syaaban 1447 H',
        entries: <PrayerTimeEntry>[
          PrayerTimeEntry(
              name: 'Subuh', time: now.subtract(const Duration(hours: 1))),
          PrayerTimeEntry(
              name: 'Zohor', time: now.add(const Duration(hours: 3))),
          PrayerTimeEntry(
              name: 'Asar', time: now.add(const Duration(hours: 6))),
          PrayerTimeEntry(
              name: 'Maghrib', time: now.add(const Duration(hours: 9))),
          PrayerTimeEntry(
              name: 'Isyak', time: now.add(const Duration(hours: 11))),
        ],
      );

      for (var i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: i));
        final key =
            '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        controller.prayerCheckinsByDate[key] = <String>[
          'Subuh',
          'Zohor',
          if (i < 3) 'Asar',
        ];
      }
    });

    testWidgets('Times header shows hijri date with offset applied',
        (tester) async {
      controller.languageCode = 'ms';
      controller.hijriOffsetDays = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomePage(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('28 Syaaban 1447H'), findsOneWidget);
    });

    testWidgets('Hijri offset setting shows preview with offset value',
        (tester) async {
      controller.hijriOffsetDays = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HijriOffsetSetting(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Today Hijri:'), findsOneWidget);
      expect(find.textContaining('29 Shaaban 1447H'), findsOneWidget);
      expect(find.textContaining('offset +1'), findsOneWidget);
    });

    testWidgets('History page renders 7-day summary rows', (tester) async {
      await tester
          .pumpWidget(MaterialApp(home: HistoryPage(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Prayer History'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(7));
      expect(find.textContaining('/5 done'), findsWidgets);
    });
  });
}

class _UiTestController extends AppController {
  _UiTestController()
      : super(
          prayerService: PrayerService(),
          locationService: LocationService(),
          notificationService: NotificationService(),
          prayerCalculationService: const PrayerCalculationService(),
          qiblaService: QiblaService(),
          tasbihStore: TasbihStore(),
        );

  @override
  Future<void> refreshPrayerData() async {}

  @override
  Future<void> refreshMonthlyData() async {}
}
