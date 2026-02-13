import 'package:flutter/material.dart';

import 'features/home/home_page.dart';
import 'features/monthly/monthly_page.dart';
import 'features/qibla/qibla_page.dart';
import 'features/settings/settings_page.dart';
import 'features/tasbih/tasbih_page.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/prayer_service.dart';
import 'services/qibla_service.dart';
import 'services/tasbih_store.dart';
import 'state/app_controller.dart';

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
  bool showSplash = true;

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

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        showSplash = false;
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
      useMaterial3: true,
    );
    final highContrastTheme = ThemeData(
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waktu Solat Malaysia',
      theme: controller.highContrast ? highContrastTheme : baseTheme,
      home: showSplash
          ? const SplashScreen()
          : AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final pages = <Widget>[
                  HomePage(controller: controller),
                  MonthlyPage(controller: controller),
                  QiblaPage(controller: controller),
                  TasbihPage(controller: controller),
                  SettingsPage(controller: controller),
                ];

                return Scaffold(
                  body: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(controller.textScale),
                    ),
                    child: pages[tabIndex],
                  ),
                  bottomNavigationBar: NavigationBar(
                    height: 72,
                    selectedIndex: tabIndex,
                    onDestinationSelected: (idx) {
                      setState(() {
                        tabIndex = idx;
                      });
                    },
                    destinations: const [
                      NavigationDestination(icon: Icon(Icons.access_time), label: 'Waktu'),
                      NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Bulanan'),
                      NavigationDestination(icon: Icon(Icons.explore), label: 'Kiblat'),
                      NavigationDestination(icon: Icon(Icons.touch_app), label: 'Tasbih'),
                      NavigationDestination(icon: Icon(Icons.settings), label: 'Tetapan'),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF00695C),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mosque, size: 84, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Waktu Solat Malaysia',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
