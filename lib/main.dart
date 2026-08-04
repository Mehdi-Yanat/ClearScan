import 'package:flutter/material.dart';

import 'pages/scanner_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF277987);
    const Color primaryDarkColor = Color(0xFF1B2835);
    const Color backgroundColor = Color(0xFFFBFBFC);
    const Color textPrimaryColor = Color(0xFF1B2835);
    const Color textMutedColor = Color(0xFF6B7280);
    const Color borderColor = Color(0xFFE5E7EB);

    final ColorScheme colorScheme = ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryDarkColor,
      onPrimaryContainer: Colors.white,
      secondary: textMutedColor,
      onSecondary: Colors.white,
      surface: backgroundColor,
      onSurface: textPrimaryColor,
      surfaceContainerHighest: const Color(0xFFF5F7FA),
      onSurfaceVariant: textMutedColor,
      outline: borderColor,
      inversePrimary: primaryDarkColor,
    );

    final ThemeData base = ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ClearScan',
      theme: base.copyWith(
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.outline),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        textTheme: base.textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        cardTheme: base.cardTheme.copyWith(
          color: colorScheme.surface,
          shadowColor: colorScheme.shadow,
        ),
        dividerColor: colorScheme.outline,
        colorScheme: colorScheme,
      ),
      home: const ScannerPage(),
    );
  }
}
