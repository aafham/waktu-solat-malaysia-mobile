import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'theme/app_tokens.dart';

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

class _WaktuSolatAppState extends State<WaktuSolatApp>
    with WidgetsBindingObserver {
  late final AppController controller;
  int tabIndex = 0;
  bool showSplash = true;
  bool dismissedOnboarding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = AppController(
      prayerService: PrayerService(),
      locationService: LocationService(),
      notificationService: NotificationService(),
      qiblaService: QiblaService(),
      tasbihStore: TasbihStore(),
    );
    controller.initialize();

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
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.refreshPrayerData();
    }
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0C1D3A),
        indicatorColor: const Color(0xFF4A5B80),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFF4C542));
          }
          return const IconThemeData(color: Color(0xFF9BB0CF));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: Color(0xFFBFD0E8),
            fontWeight: FontWeight.w600,
          );
        }),
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
      extensions: const <ThemeExtension<dynamic>>[
        PrayerHomeTokens(
          grid: 8,
          radius: 16,
          sectionGap: 16,
          cardPadding: 16,
          surface: Color(0xFF192842),
          surfaceMuted: Color(0xFF14233A),
          textMuted: Color(0xFF9FB0C8),
          accent: Color(0xFFF4C542),
          accentSoft: Color(0x33F4C542),
          shadow: BoxShadow(
            color: Color(0x2B000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          fastAnim: Duration(milliseconds: 180),
          baseAnim: Duration(milliseconds: 260),
          slowAnim: Duration(milliseconds: 360),
        ),
      ],
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

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        Intl.defaultLocale = controller.isEnglish ? 'en_US' : 'ms_MY';
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'JagaSolat',
          theme: controller.highContrast ? highContrastTheme : baseTheme,
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
                                  label: controller.tr('Waktu', 'Times'),
                                ),
                                NavigationDestination(
                                  icon: const Icon(Icons.explore),
                                  label: controller.tr('Qiblat', 'Qibla'),
                                ),
                                NavigationDestination(
                                  icon: const Icon(Icons.touch_app),
                                  label: controller.tr('Tasbih', 'Tasbih'),
                                ),
                                NavigationDestination(
                                  icon: const Icon(Icons.settings),
                                  label: controller.tr('Tetapan', 'Settings'),
                                ),
                              ],
                            ),
                ),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _loaderController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 860),
    )..forward();
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _logoFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.48, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.48, curve: Curves.easeOutBack),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.28, 0.78, curve: Curves.easeOut),
    );
    _loaderFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF091A35), Color(0xFF07142E)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 88,
                          height: 88,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33F4C542),
                                blurRadius: 26,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mosque,
                            size: 54,
                            color: Color(0xFFF4C542),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _textFade,
                      child: const Column(
                        children: [
                          Text(
                            'JagaSolat',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              letterSpacing: 0.4,
                              fontWeight: FontWeight.w800,
                              height: 1.04,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Jangan dok tinggai solat.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFC7D3E8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _loaderFade,
                      child: _SplashDotsLoader(animation: _loaderController),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashDotsLoader extends StatelessWidget {
  const _SplashDotsLoader({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF4C542);
    return SizedBox(
      width: 54,
      height: 14,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final phase = (t + index * 0.22) % 1.0;
              final wave = (1.0 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
              final scale = 0.72 + (wave * 0.45);
              final opacity = 0.28 + (wave * 0.72);
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
