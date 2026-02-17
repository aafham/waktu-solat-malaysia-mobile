import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:waktu_solat_malaysia_mobile/theme/app_theme.dart';
import 'package:waktu_solat_malaysia_mobile/widgets/splash_screen.dart';

import 'l10n/app_localizations.dart';
import 'features/home/home_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/qibla/qibla_page.dart';
import 'features/settings/settings_page.dart';
import 'features/tasbih/tasbih_page.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/prayer_calculation_service.dart';
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

class WaktuSolatApp extends StatelessWidget {
  const WaktuSolatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppController(
        prayerService: PrayerService(),
        locationService: LocationService(),
        notificationService: NotificationService(),
        prayerCalculationService: const PrayerCalculationService(),
        qiblaService: QiblaService(),
        tasbihStore: TasbihStore(),
      ),
      child: const _WaktuSolatAppView(),
    );
  }
}

class _WaktuSolatAppView extends StatefulWidget {
  const _WaktuSolatAppView();

  @override
  State<_WaktuSolatAppView> createState() => _WaktuSolatAppViewState();
}

class _WaktuSolatAppViewState extends State<_WaktuSolatAppView>
    with WidgetsBindingObserver {
  int tabIndex = 0;
  bool showSplash = true;
  bool dismissedOnboarding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AppController>().initialize();
    });

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      setState(() {
        showSplash = false;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppController>().refreshPrayerData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        Intl.defaultLocale = controller.isEnglish ? 'en_US' : 'ms_MY';
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'JagaSolat',
          theme: controller.highContrast ? highContrastTheme : baseTheme,
          locale: Locale(controller.languageCode),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            if (child == null) {
              return const SizedBox.shrink();
            }
            return AnimatedOpacity(
              opacity: controller.isLoading ? 0.98 : 1,
              duration: const Duration(milliseconds: 180),
              child: child,
            );
          },
          home: showSplash
              ? const SplashScreen()
              : Scaffold(
                  body: !controller.onboardingSeen && !dismissedOnboarding
                      ? OnboardingPage(
                          controller: controller,
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
                          child: <Widget>[
                            HomePage(controller: controller),
                            QiblaPage(controller: controller),
                            TasbihPage(controller: controller),
                            SettingsPage(controller: controller),
                          ][tabIndex],
                        ),
                  bottomNavigationBar:
                      (!controller.onboardingSeen && !dismissedOnboarding)
                          ? null
                          : NavigationBar(
                              height: 72,
                              selectedIndex: tabIndex,
                              onDestinationSelected: (idx) {
                                setState(() {
                                  tabIndex = idx;
                                });
                              },
                              destinations: [
                                NavigationDestination(
                                  icon: const Icon(Icons.home_outlined),
                                  label: controller.t('nav_times'),
                                ),
                                NavigationDestination(
                                  icon: const Icon(Icons.explore),
                                  label: controller.t('nav_qibla'),
                                ),
                                NavigationDestination(
                                  icon: const Icon(Icons.touch_app),
                                  label: controller.t('nav_tasbih'),
                                ),
                                NavigationDestination(
                                  icon: const Icon(Icons.settings),
                                  label: controller.t('nav_settings'),
                                ),
                              ],
                            ),
                ),
        );
      },
    );
  }
}
