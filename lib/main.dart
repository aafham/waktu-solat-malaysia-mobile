import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'features/home/home_page.dart';
import 'features/onboarding/onboarding_page.dart';
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
  bool dismissedOnboarding = false;

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
    const surfaceBg = Color(0xFF07142E);
    const cardBg = Color(0xFF303950);
    const cardBgSoft = Color(0xFF414A62);
    const primary = Color(0xFFF4C542);
    const secondary = Color(0xFF3CCAB5);

    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Color(0xFF1A1400),
        secondary: secondary,
        onSecondary: Color(0xFF04111F),
        surface: cardBg,
        onSurface: Color(0xFFF2F5F9),
      ),
      scaffoldBackgroundColor: surfaceBg,
      dividerColor: const Color(0xFF2A4363),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF2F5F9),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF1A1400),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEAF2FF),
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: Color(0xFF4A6183)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFFFFFFF);
          }
          return const Color(0xFFCDD6E6);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF12D568);
          }
          return const Color(0xFF5B657F);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardBgSoft,
        selectedColor: const Color(0xFF2A4970),
        side: const BorderSide(color: Color(0xFF365577)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF0C1D3A),
        indicatorColor: Color(0xFF3A4560),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: Color(0xFFB7C6DC)),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: Color(0xFFEAF2FF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBgSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E5D82)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E5D82)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF12213A),
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
      title: 'JagaSolat',
      theme: controller.highContrast ? highContrastTheme : baseTheme,
      home: showSplash
          ? const SplashScreen()
          : AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final pages = <Widget>[
                  HomePage(
                    controller: controller,
                    onNavigateToTab: (index) {
                      setState(() {
                        tabIndex = index;
                      });
                    },
                  ),
                  QiblaPage(controller: controller),
                  TasbihPage(controller: controller),
                  SettingsPage(controller: controller),
                ];

                return Scaffold(
                  body: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : !controller.onboardingSeen && !dismissedOnboarding
                      ? OnboardingPage(
                          onSelesai: () async {
                            await controller.completeOnboarding();
                            setState(() {
                              dismissedOnboarding = true;
                            });
                          },
                        )
                      : MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(controller.textScale),
                          ),
                          child: pages[tabIndex],
                        ),
                  bottomNavigationBar: controller.isLoading
                      ? null
                      : !controller.onboardingSeen && !dismissedOnboarding
                          ? null
                          : NavigationBar(
                              height: 72,
                              selectedIndex: tabIndex,
                              onDestinationSelected: (idx) {
                                setState(() {
                                  tabIndex = idx;
                                });
                              },
                              destinations: const [
                                NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Waktu'),
                                NavigationDestination(icon: Icon(Icons.explore), label: 'Qiblat'),
                                NavigationDestination(icon: Icon(Icons.touch_app), label: 'Zikir'),
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
      backgroundColor: Color(0xFF07152F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mosque, size: 84, color: Color(0xFFF3C623)),
            SizedBox(height: 20),
            Text(
              'JagaSolat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            CircularProgressIndicator(color: Color(0xFFF3C623)),
          ],
        ),
      ),
    );
  }
}
