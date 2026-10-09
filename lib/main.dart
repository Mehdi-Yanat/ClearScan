import 'package:clear_scan/screens/documents_screen.dart';
import 'package:clear_scan/screens/notifications_screen.dart';
import 'package:flutter/material.dart';

import 'screens/workshop_screen.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screens.dart';
import 'screens/splash_screen.dart';
import 'services/app_lock_service.dart';
import 'theme/app_theme.dart'; // AppTheme, AppPreferences, themeModeNotifier, localeNotifier
import 'l10n/app_localizations.dart' as loc;

// NOTE: `themeModeNotifier` now lives in theme/app_theme.dart so every screen
// shares the same instance. Do NOT declare it again here.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  themeModeNotifier.value = await AppPreferences.getThemeMode();
  localeNotifier.value = await AppPreferences.getLocale();
  await AppLockService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => ValueListenableBuilder<Locale>(
        valueListenable: localeNotifier,
        builder: (context, locale, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ClearScan',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: mode,
          locale: locale,
          localizationsDelegates: loc.AppLocalizations.localizationsDelegates,
          supportedLocales: loc.AppLocalizations.supportedLocales,
          routes: {
            '/home': (context) => const HomeScreen(),
            '/onboarding': (context) => const OnboardingPage(),
            '/splash': (context) => const SplashPage(),
            '/documents': (context) => const DocumentsScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/workshop': (context) => const WorkshopScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
          home: const _AppEntry(),
          builder: (context, child) =>
              AppLockGate(child: child ?? const SizedBox.shrink()),
        ),
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
