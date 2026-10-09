import 'package:clear_scan/screens/documents_screen.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screens.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart'; // AppTheme, AppPreferences, themeModeNotifier

// NOTE: `themeModeNotifier` now lives in theme/app_theme.dart so every screen
// shares the same instance. Do NOT declare it again here.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  themeModeNotifier.value = await AppPreferences.getThemeMode();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder handles adding/removing the listener for us.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ClearScan',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: mode,
        routes: {
          '/home': (context) => const HomeScreen(),
          '/onboarding': (context) => const OnboardingPage(),
          '/splash': (context) => const SplashPage(),
          '/documents': (context) => const DocumentsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
        home: const _AppEntry(),
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final seen = await OnboardingPage.hasSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => seen ? const SplashPage() : const OnboardingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme background instead of Colors.white: no white flash in dark mode.
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
