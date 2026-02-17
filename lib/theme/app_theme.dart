
import 'package:flutter/material.dart';
import 'app_tokens.dart';

const _surfaceBg = Color(0xFF07142E);
const _cardBg = Color(0xFF303950);
const _cardBgSoft = Color(0xFF414A62);
const _primary = Color(0xFFF4C542);
const _secondary = Color(0xFF3CCAB5);

final baseTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: _primary,
    onPrimary: Color(0xFF1A1400),
    secondary: _secondary,
    onSecondary: Color(0xFF04111F),
    surface: _cardBg,
    onSurface: Color(0xFFF2F5F9),
  ),
  scaffoldBackgroundColor: _surfaceBg,
  dividerColor: const Color(0xFF2A4363),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFFF2F5F9),
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: const CardThemeData(
    color: _cardBg,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _primary,
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
    backgroundColor: _cardBgSoft,
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
    fillColor: _cardBgSoft,
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
      borderSide: const BorderSide(color: _primary, width: 1.4),
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
