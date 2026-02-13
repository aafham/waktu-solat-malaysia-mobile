import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ms_MY');
  Intl.defaultLocale = 'ms_MY';
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
    const surfaceBg = Color(0xFFE7EEEC);
    const cardBg = Color(0xFFF2F6F5);
    const primary = Color(0xFF0A7E70);
    const secondary = Color(0xFF7FBEB3);

    final baseTheme = ThemeData(
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Color(0xFF12312C),
        surface: cardBg,
        onSurface: Color(0xFF1A2A27),
      ),
      scaffoldBackgroundColor: surfaceBg,
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0A6358),
          side: const BorderSide(color: Color(0xFF8AAEA8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFD4E7E2),
        selectedColor: const Color(0xFFB5D8D0),
        side: const BorderSide(color: Color(0xFF9ABCB5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFFDDE9E6),
        indicatorColor: Color(0xFFC0DFD8),
        surfaceTintColor: Colors.transparent,
        iconTheme: MaterialStatePropertyAll(
          IconThemeData(color: Color(0xFF4B5855)),
        ),
        labelTextStyle: MaterialStatePropertyAll(
          TextStyle(
            color: Color(0xFF2F3E3B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F6F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB7CBC6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB7CBC6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF163D36),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
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
