import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
// Default locale is English; will be overridden by saved preference if any.
final localeNotifier = ValueNotifier<Locale>(const Locale('en'));

// Original AppColors class for backward compatibility
class AppColors {
  // Light theme colors
  static const Color _lightInk = Color(0xFF12303A);
  static const Color _lightPrimary = Color(0xFF14909A);
  static const Color _lightPrimaryLight = Color(0xFFE3F3F4);
  static const Color _lightHeroDark = Color(0xFF0F2A33);
  static const Color _lightBackground = Color(0xFFF5F8FA);
  static const Color _lightSurface = Colors.white;
  static const Color _lightBorder = Color(0xFFE6ECEF);
  static const Color _lightTextMuted = Color(0xFF6B7C85);
  static const Color _lightTextHint = Color(0xFF9AA8B0);

  // Dark theme colors
  static const Color _darkInk = Color(0xFFE0E6ED);
  static const Color _darkPrimary = Color(0xFF2CC4CF);
  static const Color _darkPrimaryLight = Color(0xFF0F2A33);
  static const Color _darkHeroDark = Color(0xFF14909A);
  static const Color _darkBackground = Color(0xFF0B1E26);
  static const Color _darkSurface = Color(0xFF12303A);
  static const Color _darkBorder = Color(0xFF2A3D45);
  static const Color _darkTextMuted = Color(0xFF8A99A5);
  static const Color _darkTextHint = Color(0xFF6B7C85);

  // Theme-aware getters
  static Color ink(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkInk : _lightInk;

  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkPrimary
      : _lightPrimary;

  static Color primaryLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkPrimaryLight
      : _lightPrimaryLight;

  static Color heroDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkHeroDark
      : _lightHeroDark;

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkBackground
      : _lightBackground;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkSurface
      : _lightSurface;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkBorder
      : _lightBorder;

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkTextMuted
      : _lightTextMuted;

  static Color textHint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkTextHint
      : _lightTextHint;

  // Static colors that don't change
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF5A524);
  static const Color success = Color(0xFF2FB67C);
}

// AppPreferences for theme and locale management
class AppPreferences {
  static const String themeModeKey = 'theme_mode';
  static const String localeKey = 'app_locale';
  static const String systemDefault = 'system';
  static const String light = 'light';
  static const String dark = 'dark';

  static Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString(localeKey);
    if (langCode == null) return const Locale('en');
    // Support language_COUNTRY format? We'll just split by '_'
    final parts = langCode.split('_');
    final languageCode = parts[0];
    final countryCode = parts.length > 1 ? parts[1] : null;
    if (countryCode != null) {
      return Locale(languageCode, countryCode);
    } else {
      return Locale(languageCode);
    }
  }

  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    final String localeString =
        locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
    await prefs.setString(localeKey, localeString);
  }

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mode = prefs.getString(themeModeKey);
    switch (mode) {
      case light:
        return ThemeMode.light;
      case dark:
        return ThemeMode.dark;
      case systemDefault:
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = light;
        break;
      case ThemeMode.dark:
        modeString = dark;
        break;
      case ThemeMode.system:
        modeString = systemDefault;
        break;
    }
    await prefs.setString(themeModeKey, modeString);
  }
}

// Light theme colors (using original names for compatibility)
class _LightColors {
  static const ink = Color(0xFF12303A);
  static const primary = Color(0xFF14909A);
  static const surface = Colors.white;
  static const border = Color(0xFFE6ECEF);
  static const textMuted = Color(0xFF6B7C85);
}

// Dark theme colors
class _DarkColors {
  static const ink = Color(0xFFE0E6ED);
  static const primary = Color(0xFF2CC4CF);
  static const surface = Color(0xFF12303A);
  static const border = Color(0xFF2A3D45);
  static const textMuted = Color(0xFF8A99A5);
}

class AppTheme {
  static ThemeData lightTheme() {
    const f = 'Poppins';
    return ThemeData(
      useMaterial3: true,
      fontFamily: f,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F8FA),
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: const Color(0xFF14909A),
        primary: const Color(0xFF14909A),
        onPrimary: Colors.white,
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _LightColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _LightColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _LightColors.ink,
        ),
        bodyMedium: TextStyle(fontSize: 13, color: _LightColors.ink),
        bodySmall: TextStyle(fontSize: 11, color: _LightColors.textMuted),
      ),
      cardTheme: CardThemeData(
        color: _LightColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _LightColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _LightColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        selectedColor: _LightColors.primary,
        backgroundColor: _LightColors.surface,
        side: const BorderSide(color: _LightColors.border),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _LightColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _LightColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _LightColors.primary, width: 2),
        ),
        filled: true,
        fillColor: _LightColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    const f = 'Poppins';
    return ThemeData(
      useMaterial3: true,
      fontFamily: f,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1E26),
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: const Color(0xFF2CC4CF),
        primary: const Color(0xFF2CC4CF),
        onPrimary: Colors.white,
        surface: const Color(0xFF12303A),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _DarkColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _DarkColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _DarkColors.ink,
        ),
        bodyMedium: TextStyle(fontSize: 13, color: _DarkColors.ink),
        bodySmall: TextStyle(fontSize: 11, color: _DarkColors.textMuted),
      ),
      cardTheme: CardThemeData(
        color: _DarkColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _DarkColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _DarkColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        selectedColor: _DarkColors.primary,
        backgroundColor: _DarkColors.surface,
        side: const BorderSide(color: _DarkColors.border),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _DarkColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _DarkColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _DarkColors.primary, width: 2),
        ),
        filled: true,
        fillColor: _DarkColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // Backward compatibility function
  ThemeData buildAppTheme() {
    return lightTheme();
  }
}
