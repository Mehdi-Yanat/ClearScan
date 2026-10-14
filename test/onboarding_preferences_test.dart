import 'package:clear_scan/screens/app/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('hasSeen is false when no onboarding preference is saved', () async {
    expect(await OnboardingPage.hasSeen(), isFalse);
  });

  test('markSeen persists onboarding completion', () async {
    await OnboardingPage.markSeen();

    expect(await OnboardingPage.hasSeen(), isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool('onboarding_seen'),
      isTrue,
    );
  });

  test('hasSeen reads an existing onboarding preference', () async {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});

    expect(await OnboardingPage.hasSeen(), isTrue);
  });
}
