import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised design tokens for the Spiritual Q&A app.
///
/// Contains colour definitions, gradient presets, and complete
/// [ThemeData] for light and dark modes.
class AppTheme {
  // Figma Colors
  static const Color purple100 = Color(0xFFE9D5FF); // Approximate Purple-100
  static const Color blue50 = Color(0xFFEFF6FF); // Approximate Blue-50
  static const Color teal50 = Color(0xFFF0FDFA); // Approximate Teal-50
  static const Color teal500 = Color(0xFF14B8A6); // Teal-500
  static const Color cyan500 = Color(0xFF06B6D4); // Cyan-500
  static const Color purple500 = Color(0xFFA855F7); // Purple-500
  static const Color fuchsia500 = Color(0xFFD946EF); // Fuchsia-500

  static const Color gray900 = Color(0xFF111827);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color purple300 = Color(0xFFD8B4FE);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple100, blue50, teal50],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [teal500, cyan500],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [purple500, fuchsia500],
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: teal500,
      brightness: Brightness.light,
      primary: teal500,
      secondary: purple500,
      surface: Colors.white.withValues(alpha: 0.9), // For glass effect base
    ),
    scaffoldBackgroundColor:
        Colors.transparent, // Important for GradientScaffold
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: gray900,
      displayColor: gray900,
      decorationColor: gray900,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: teal500, width: 2),
      ),
      hintStyle: const TextStyle(color: gray600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
  );

  // Dark theme largely mirrors light but with adapted colors
  // For now, focusing on Light Theme as per wireframes implied style
  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: teal500,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );
}
