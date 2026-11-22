import 'package:flutter/material.dart';

/// Colours from the FinBridge Figma design: navy for structure and main actions, mint for
/// positive states and highlights, soft blue-grey surfaces.
class FbColors {
  static const primary = Color(0xFF0B2A55); // navy, 14:1 on white
  static const primaryLight = Color(0xFFE8EEF8); // pale blue fill (chips, inputs, info boxes)
  static const accent = Color(0xFF7DE3C3); // mint (highlights on navy, success pills)
  static const accentDark = Color(0xFF0F766E); // teal text on light backgrounds
  static const success = Color(0xFF0F766E);
  static const successBg = Color(0xFFDDF7EE);
  static const danger = Color(0xFFB42318);
  static const dangerBg = Color(0xFFFDE4E2);
  static const warning = Color(0xFFB54708);
  static const warningBg = Color(0xFFFEF0C7);
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const textMuted = Color(0xFF526077);
}

ThemeData buildTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: FbColors.primary,
    primary: FbColors.primary,
    secondary: FbColors.accentDark,
    surface: FbColors.surface,
    error: FbColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: FbColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: FbColors.surface,
      foregroundColor: FbColors.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(color: FbColors.primary, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FbColors.primary,
        minimumSize: const Size.fromHeight(54), // touch targets well above 48 dp
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FbColors.primary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: FbColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: FbColors.primary)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FbColors.primaryLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FbColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    ),
    cardTheme: CardThemeData(
      color: FbColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: FbColors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: FbColors.surface,
      indicatorColor: FbColors.successBg,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}
