import 'package:flutter/material.dart';

/// Colours taken from the Figma prototype (report Section 15.4).
class FbColors {
  static const primary = Color(0xFF064E3B); // deep green, 9.7:1 on white
  static const primaryLight = Color(0xFFE6F2EE);
  static const success = Color(0xFF0E7A66); // darkened teal for small text
  static const successBg = Color(0xFFF0FDF4);
  static const danger = Color(0xFFB42318);
  static const dangerBg = Color(0xFFFEE4E2);
  static const warning = Color(0xFFB54708);
  static const warningBg = Color(0xFFFEF0C7);
  static const background = Color(0xFFF7F9FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const textMuted = Color(0xFF475467);
}

ThemeData buildTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: FbColors.primary,
    primary: FbColors.primary,
    surface: FbColors.surface,
    error: FbColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: FbColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: FbColors.primary,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FbColors.primary,
        minimumSize: const Size.fromHeight(52), // touch targets well above 48 dp
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: FbColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: FbColors.border),
      ),
    ),
  );
}
