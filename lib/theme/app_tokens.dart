import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

@immutable
class PrayerHomeTokens extends ThemeExtension<PrayerHomeTokens> {
  const PrayerHomeTokens({
    required this.grid,
    required this.radius,
    required this.sectionGap,
    required this.cardPadding,
    required this.surface,
    required this.surfaceMuted,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.shadow,
    required this.fastAnim,
    required this.baseAnim,
    required this.slowAnim,
  });

  const PrayerHomeTokens.fallback()
      : grid = 8,
        radius = 16,
        sectionGap = 16,
        cardPadding = 16,
        surface = const Color(0xFF1A243D),
        surfaceMuted = const Color(0xFF121D33),
        textMuted = const Color(0xFF9FB0C8),
        accent = const Color(0xFFF4C542),
        accentSoft = const Color(0x33F4C542),
        shadow = const BoxShadow(
          color: Color(0x22000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
        fastAnim = const Duration(milliseconds: 180),
        baseAnim = const Duration(milliseconds: 260),
        slowAnim = const Duration(milliseconds: 360);

  final double grid;
  final double radius;
  final double sectionGap;
  final double cardPadding;
  final Color surface;
  final Color surfaceMuted;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final BoxShadow shadow;
  final Duration fastAnim;
  final Duration baseAnim;
  final Duration slowAnim;

  @override
  PrayerHomeTokens copyWith({
    double? grid,
    double? radius,
    double? sectionGap,
    double? cardPadding,
    Color? surface,
    Color? surfaceMuted,
    Color? textMuted,
    Color? accent,
    Color? accentSoft,
    BoxShadow? shadow,
    Duration? fastAnim,
    Duration? baseAnim,
    Duration? slowAnim,
  }) {
    return PrayerHomeTokens(
      grid: grid ?? this.grid,
      radius: radius ?? this.radius,
      sectionGap: sectionGap ?? this.sectionGap,
      cardPadding: cardPadding ?? this.cardPadding,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      shadow: shadow ?? this.shadow,
      fastAnim: fastAnim ?? this.fastAnim,
      baseAnim: baseAnim ?? this.baseAnim,
      slowAnim: slowAnim ?? this.slowAnim,
    );
  }

  @override
  ThemeExtension<PrayerHomeTokens> lerp(
    covariant ThemeExtension<PrayerHomeTokens>? other,
    double t,
  ) {
    if (other is! PrayerHomeTokens) {
      return this;
    }
    return PrayerHomeTokens(
      grid: lerpDouble(grid, other.grid, t) ?? grid,
      radius: lerpDouble(radius, other.radius, t) ?? radius,
      sectionGap: lerpDouble(sectionGap, other.sectionGap, t) ?? sectionGap,
      cardPadding: lerpDouble(cardPadding, other.cardPadding, t) ?? cardPadding,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceMuted:
          Color.lerp(surfaceMuted, other.surfaceMuted, t) ?? surfaceMuted,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
      shadow: BoxShadow.lerp(shadow, other.shadow, t) ?? shadow,
      fastAnim: t < 0.5 ? fastAnim : other.fastAnim,
      baseAnim: t < 0.5 ? baseAnim : other.baseAnim,
      slowAnim: t < 0.5 ? slowAnim : other.slowAnim,
    );
  }
}

extension PrayerHomeThemeX on ThemeData {
  PrayerHomeTokens get prayerHomeTokens =>
      extension<PrayerHomeTokens>() ?? const PrayerHomeTokens.fallback();
}

extension PrayerHomeContextX on BuildContext {
  PrayerHomeTokens get prayerHomeTokens => Theme.of(this).prayerHomeTokens;
}
