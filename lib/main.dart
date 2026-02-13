import 'package:flutter/material.dart';

import 'package:waktu_solat_malaysia_mobile/features/home/home_page.dart';
import 'package:waktu_solat_malaysia_mobile/features/qibla/qibla_page.dart';
import 'package:waktu_solat_malaysia_mobile/features/settings/settings_page.dart';
import 'package:waktu_solat_malaysia_mobile/features/tasbih/tasbih_page.dart';
import 'package:waktu_solat_malaysia_mobile/services/location_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/notification_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/prayer_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/qibla_service.dart';
import 'package:waktu_solat_malaysia_mobile/services/tasbih_store.dart';
import 'package:waktu_solat_malaysia_mobile/state/app_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WaktuSolatApp());
}

class WaktuSolatApp extends StatefulWidget {
  const WaktuSolatApp({super.key});

  @override
  State<WaktuSolatApp> createState() => _WaktuSolatAppState();
}

class _WaktuSolatAppState extends State<WaktuSolatApp> {
  late final AppController controller;
  int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = AppController(
      prayerService: PrayerService(),
      locationService: LocationService(),
      notificationService: NotificationService(),
      qiblaService: QiblaService(),
      tasbihStore: TasbihStore(),
    );
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waktu Solat Malaysia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        useMaterial3: true,
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final pages = <Widget>[
            HomePage(controller: controller),
            QiblaPage(controller: controller),
            TasbihPage(controller: controller),
            SettingsPage(controller: controller),
          ];

          return Scaffold(
            body: pages[tabIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: tabIndex,
              onDestinationSelected: (idx) {
                setState(() {
                  tabIndex = idx;
                });
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.access_time), label: 'Waktu'),
                NavigationDestination(icon: Icon(Icons.explore), label: 'Kiblat'),
                NavigationDestination(icon: Icon(Icons.touch_app), label: 'Tasbih'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          );
        },
      ),
    );
  }
}
