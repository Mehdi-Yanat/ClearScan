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

  testWidgets('first launch completes onboarding and opens the home screen', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();

    await app.main();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(preferences.getBool('onboarding_seen'), isTrue);
  });

  testWidgets('skipping onboarding opens the home screen', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();

    await app.main();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(preferences.getBool('onboarding_seen'), isTrue);
  });

  testWidgets('returning launch skips onboarding and opens home', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_seen', true);

    await app.main();
    await tester.pump();
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
