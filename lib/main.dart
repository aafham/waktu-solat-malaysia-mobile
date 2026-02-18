import 'dart:async';

import 'package:app_links/app_links.dart';
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
import 'services/widget_update_service.dart';
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
        widgetUpdateService: const WidgetUpdateService(),
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
  static const _minSplashDuration = Duration(milliseconds: 900);
  static const _maxSplashDuration = Duration(milliseconds: 2500);

  int tabIndex = 0;
  bool showSplash = true;
  bool dismissedOnboarding = false;
  bool _minSplashElapsed = false;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _deepLinkSub;
  Timer? _minSplashTimer;
  Timer? _maxSplashTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final controller = context.read<AppController>();
      unawaited(() async {
        await controller.initialize();
        if (!mounted) {
          return;
        }
        _tryDismissSplash(controller);
      }());
      unawaited(_setupDeepLinks());
    });

    _minSplashTimer = Timer(_minSplashDuration, () {
      if (!mounted) return;
      _minSplashElapsed = true;
      _tryDismissSplash(context.read<AppController>());
    });

    _maxSplashTimer = Timer(_maxSplashDuration, () {
      if (!mounted || !showSplash) return;
      setState(() {
        showSplash = false;
      });
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _minSplashTimer?.cancel();
    _maxSplashTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppController>().refreshPrayerData();
    }
  }

  Future<void> _setupDeepLinks() async {
    _appLinks ??= AppLinks();
    final initial = await _appLinks!.getInitialLink();
    if (initial != null) {
      _handleDeepLink(initial);
    }
    _deepLinkSub ??= _appLinks!.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    final shouldOpenTimes = uri.scheme == 'myapp' &&
        (uri.host == 'times' || uri.path.toLowerCase().contains('times'));
    if (!shouldOpenTimes || !mounted) {
      return;
    }
    setState(() {
      tabIndex = 0;
      dismissedOnboarding = true;
      showSplash = false;
    });
  }

  void _tryDismissSplash(AppController controller) {
    if (!mounted || !showSplash || !_minSplashElapsed) {
      return;
    }
    if (controller.isLoading) {
      return;
    }
    setState(() {
      showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    final languageCode = context.select<AppController, String>(
      (c) => c.languageCode,
    );
    final isEnglish = context.select<AppController, bool>((c) => c.isEnglish);
    final highContrast = context.select<AppController, bool>(
      (c) => c.highContrast,
    );

    Intl.defaultLocale = isEnglish ? 'en_US' : 'ms_MY';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JagaSolat',
      theme: highContrast ? highContrastTheme : baseTheme,
      locale: Locale(languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => child ?? const SizedBox.shrink(),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            children: [
              Scaffold(
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
                    : <Widget>[
                        HomePage(controller: controller),
                        QiblaPage(controller: controller),
                        TasbihPage(controller: controller),
                        SettingsPage(controller: controller),
                      ][tabIndex],
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
              if (showSplash) const Positioned.fill(child: SplashScreen()),
            ],
          );
        },
      ),
    );
  }
}
