import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for Sacred Wisdom — Celestial direction.
///
/// Palette: deep indigo + violet, dark by default. All surface/ink
/// values are provided in both light and dark variants so callers
/// can resolve them via `Theme.of(context).brightness`.
class AppTheme {
  // ── Celestial accent palette ───────────────────────────────
  static const Color accent = Color(0xFF4F46E5);        // indigo-600
  static const Color accentSoft = Color(0xFF6366F1);    // indigo-500
  static const Color accent2 = Color(0xFF9333EA);       // purple-600 (design spec accent2)
  static const Color accent2Soft = Color(0xFFA855F7);   // purple-400 (design spec accent2Soft)
  static const Color gradientStop2 = Color(0xFF7C3AED); // violet-600, used in primaryGradient only

  // ── Celestial light backgrounds ────────────────────────────
  static const Color bgLight1 = Color(0xFFE0E7FF);   // indigo-100
  static const Color bgLight2 = Color(0xFFDDD6FE);   // violet-100
  static const Color bgLightBase = Color(0xFFF8FAFF);

  // ── Celestial dark backgrounds ─────────────────────────────
  static const Color bgDark1 = Color(0xFF312E81);    // indigo-900
  static const Color bgDark2 = Color(0xFF1E1B4B);    // indigo-950
  static const Color bgDarkBase = Color(0xFF020617); // near-black
  static const Color bgDarkSurface = Color(0xFF0B0A1F);

  // ── Surface ────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xBFFFFFFF);         // white/75
  static const Color surfaceDark = Color(0x801E1B4B);          // indigo-dark/50
  static const Color borderLight = Color(0x1F4F46E5);          // indigo/12
  static const Color borderDark = Color(0x24A5B4FC);           // indigo-200/14

  // ── Ink ────────────────────────────────────────────────────
  static const Color inkLight = Color(0xFF0F0D1F);
  static const Color inkDark = Color(0xFFEDE9FE);   // violet-100
  static const Color mutedLight = Color(0xFF4B4966);
  static const Color mutedDark = Color(0xFFA5B4FC);  // indigo-200

  // ── Gradients ──────────────────────────────────────────────
  /// Primary CTA gradient — indigo → violet.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, gradientStop2],
  );

  /// Light-mode page background.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgLight1, bgLightBase, bgLight2],
  );

  /// Dark-mode page background — deep indigo starfield base.
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDarkBase, bgDarkSurface],
  );

  // ── Display typography (Playfair Display for headings) ────
  static TextTheme _withDisplayFont(TextTheme base, Color inkColor) {
    final playfair = GoogleFonts.playfairDisplay;
    return base.copyWith(
      displaySmall: playfair(fontSize: 36, fontWeight: FontWeight.w500, color: inkColor),
      headlineLarge: playfair(fontSize: 32, fontWeight: FontWeight.w500, color: inkColor),
      headlineMedium: playfair(fontSize: 28, fontWeight: FontWeight.w500, color: inkColor),
      headlineSmall: playfair(fontSize: 24, fontWeight: FontWeight.w500, color: inkColor),
      titleLarge: playfair(fontSize: 18, fontWeight: FontWeight.w500, color: inkColor),
    );
  }

  // ── Light theme ────────────────────────────────────────────
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      primary: accent,
      secondary: accent2,
      surface: surfaceLight,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: _withDisplayFont(
      GoogleFonts.interTextTheme().apply(
        bodyColor: inkLight,
        displayColor: inkLight,
        decorationColor: inkLight,
      ),
      inkLight,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      hintStyle: const TextStyle(color: mutedLight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: accent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
  );

  // ── Dark theme ─────────────────────────────────────────────
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      primary: accentSoft,
      secondary: accent2Soft,
      surface: surfaceDark,
      onSurface: inkDark,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: _withDisplayFont(
      GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: inkDark,
        displayColor: inkDark,
        decorationColor: inkDark,
      ),
      inkDark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x0AFFFFFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentSoft, width: 2),
      ),
      hintStyle: const TextStyle(color: mutedDark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: accent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
