import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF12303A);
  static const primary = Color(0xFF14909A);
  static const primaryLight = Color(0xFFE3F3F4);
  static const heroDark = Color(0xFF0F2A33);
  static const background = Color(0xFFF5F8FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE6ECEF);
  static const textMuted = Color(0xFF6B7C85);
  static const textHint = Color(0xFF9AA8B0);
  static const danger = Color(0xFFE5484D);
  static const warning = Color(0xFFF5A524);
  static const success = Color(0xFF2FB67C);
}

// Add Poppins (Regular 400, Medium 500, Bold 700) to pubspec.yaml fonts.
ThemeData buildAppTheme() {
  const f = 'Poppins';
  return ThemeData(
    useMaterial3: true,
    fontFamily: f,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
      bodyMedium: TextStyle(fontSize: 13, color: AppColors.ink),
      bodySmall: TextStyle(fontSize: 11, color: AppColors.textMuted),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
    ),
  );
}
