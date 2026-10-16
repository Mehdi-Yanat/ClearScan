import 'package:clear_scan/main.dart' as app;
import 'package:clear_scan/screens/app/home_screen.dart';
import 'package:clear_scan/screens/app/onboarding_screen.dart';
import 'package:clear_scan/screens/app/splash_screen.dart';
import 'package:flutter/material.dart' show ElevatedButton, TextButton;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The onboarding and splash screens run repeating animations, so
  // pumpAndSettle() would never settle. Pump until the widget appears instead.
  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration step = const Duration(milliseconds: 200),
    int maxPumps = 150,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  testWidgets('first launch completes onboarding and opens the home screen', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();

    await app.main();
    await pumpUntilFound(tester, find.byType(OnboardingPage));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await pumpUntilFound(tester, find.byType(HomeScreen));
    expect(preferences.getBool('onboarding_seen'), isTrue);
  });

  testWidgets('skipping onboarding opens the home screen', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();

    await app.main();
    await pumpUntilFound(tester, find.byType(OnboardingPage));

    await tester.tap(find.widgetWithText(TextButton, 'Skip'));
    await pumpUntilFound(tester, find.byType(HomeScreen));
    expect(preferences.getBool('onboarding_seen'), isTrue);
  });

  testWidgets('returning launch skips onboarding and opens home', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_seen', true);

    await app.main();
    await pumpUntilFound(tester, find.byType(SplashPage));
    expect(find.byType(OnboardingPage), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await pumpUntilFound(tester, find.byType(HomeScreen));
  });
}
