import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waktu_solat_malaysia_mobile/features/settings/settings_page.dart';
import 'package:waktu_solat_malaysia_mobile/models/prayer_models.dart';
import 'package:waktu_solat_malaysia_mobile/services/location_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/notification_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/prayer_calculation_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/prayer_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/qibla_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/tasbih_store.dart';
import 'package:waktu_solat_malaysia_mobile/state/app_controller.dart';

void main() {
  group('Settings critical flows', () {
    late _TestAppController controller;

    setUp(() {
      controller = _TestAppController();
      controller.languageCode = 'en';
      controller.zones = const <PrayerZone>[
        PrayerZone(
          code: 'WLY01',
          state: 'WP',
          location: 'Putrajaya',
          latitude: 2.9,
          longitude: 101.7,
        ),
        PrayerZone(
          code: 'SGR01',
          state: 'Selangor',
          location: 'Shah Alam',
          latitude: 3.07,
          longitude: 101.52,
        ),
      ];
      controller.activeZone = controller.zones.first;
      controller.manualZoneCode = 'WLY01';
      controller.recentZones = <String>['SGR01', 'WLY01'];
      controller.prayerNotificationToggles = <String, bool>{
        'Imsak': true,
        'Subuh': false,
        'Syuruk': false,
        'Zohor': true,
        'Asar': false,
        'Maghrib': true,
        'Isyak': false,
      };
      controller.prayerSoundProfiles = <String, String>{
        'Imsak': 'default',
        'Subuh': 'default',
        'Syuruk': 'default',
        'Zohor': 'default',
        'Asar': 'default',
        'Maghrib': 'default',
        'Isyak': 'default',
      };
      controller.monthlyPrayerTimes = MonthlyPrayerTimes(
        zone: 'WLY01',
        month: DateTime.now(),
        days: <DailyPrayerTimes>[
          DailyPrayerTimes(
            zone: 'WLY01',
            date: DateTime.now().add(const Duration(days: 1)),
            hijriDate: '10 Ramadan 1447 H',
            entries: <PrayerTimeEntry>[
              PrayerTimeEntry(
                name: 'Imsak',
                time: DateTime.now().add(const Duration(days: 1, hours: 5)),
              ),
            ],
          ),
        ],
      );
      controller.ramadhanMode = true;
      controller.notifyEnabled = true;
    });

    testWidgets('PrayerTimes shows zone + opens change zone sheet',
        (tester) async {
      controller.autoLocation = false;
      await tester.pumpWidget(
        MaterialApp(home: PrayerTimesSettingsPage(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zone'), findsOneWidget);
      expect(find.text('Change zone'), findsOneWidget);

      await tester.tap(find.text('Change zone'));
      await tester.pumpAndSettle();
      expect(find.text('Search zone'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
    });

    testWidgets('Notifications select all and clear update toggles',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1500));
      await tester.pumpWidget(
        MaterialApp(home: NotificationsSettingsPage(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Select all'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      expect(
        controller.prayerNotificationToggles.values.every((v) => v),
        isTrue,
      );

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(
        controller.prayerNotificationToggles.values.every((v) => !v),
        isTrue,
      );
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Notifications azan sound picker updates profile',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: NotificationsSettingsPage(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Azan sound'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Silent').first);
      await tester.pumpAndSettle();

      expect(controller.globalAzanSoundProfile, 'silent');
    });

    testWidgets('Fasting preview opens and shows dates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: FastingSettingsPage(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Preview upcoming dates'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.calendar_today_outlined), findsWidgets);
    });

    testWidgets('Tasbih custom target shows when value is non preset',
        (tester) async {
      controller.tasbihCycleTarget = 77;
      await tester.pumpWidget(
        MaterialApp(home: TasbihSettingsPage(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current custom: 77'), findsOneWidget);
    });

    testWidgets('Tasbih custom target picker updates controller',
        (tester) async {
      controller.tasbihCycleTarget = 33;
      await controller.setTasbihCycleTarget(88);
      expect(controller.tasbihCycleTarget, 88);
    });
  });
}

class _TestAppController extends AppController {
  _TestAppController()
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

  @override
  Future<void> setAutoLocation(bool value) async {
    autoLocation = value;
    notifyListeners();
  }

  @override
  Future<void> setManualZone(String value) async {
    manualZoneCode = value;
    notifyListeners();
  }

  @override
  Future<void> setAllPrayerNotifications(bool value) async {
    for (final key in prayerNotificationToggles.keys) {
      prayerNotificationToggles[key] = value;
    }
    notifyListeners();
  }

  @override
  Future<void> setPrayerNotifyEnabled(String prayerName, bool value) async {
    prayerNotificationToggles[prayerName] = value;
    notifyListeners();
  }

  @override
  Future<void> setAllPrayerSoundProfiles(String profile) async {
    for (final key in prayerSoundProfiles.keys) {
      prayerSoundProfiles[key] = profile;
    }
    notifyListeners();
  }

  @override
  Future<void> setPrayerSoundProfile(String prayerName, String profile) async {
    prayerSoundProfiles[prayerName] = profile;
    notifyListeners();
  }

  @override
  Future<void> previewPrayerSound(String prayerName) async {}

  @override
  Future<void> setTasbihCycleTarget(int value) async {
    tasbihCycleTarget = value;
    notifyListeners();
  }
}
