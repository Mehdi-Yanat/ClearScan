import 'package:flutter_test/flutter_test.dart';
import 'package:clear_scan/main.dart';
import 'package:clear_scan/screens/app/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('MyApp shows onboarding on first launch', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
