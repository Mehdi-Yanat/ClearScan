// Integration tests for the main workshop tool screens
// These tests verify navigation to each major tool screen works correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clear_scan/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Skip onboarding by marking it as seen.
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});
  });

  testWidgets('Navigate to each workshop tool screen', (
    WidgetTester tester,
  ) async {
    // Start the app.
    app.main();
    await tester.pumpAndSettle();

    // Open the Workshop screen via bottom navigation (icon "build_outlined").
    await tester.tap(find.byIcon(Icons.build_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Workshop'), findsWidgets);

    // Helper to navigate back using the AppBar back button.
    Future<void> goBack() async {
      // The back button usually has a tooltip "Back".
      final backFinder = find.byTooltip('Back');
      if (backFinder.evaluate().isNotEmpty) {
        await tester.tap(backFinder);
        await tester.pumpAndSettle();
      }
    }

    // --- Convert tools ---
    // PDF to Image
    await tester.tap(find.text('PDF to Image'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'PDF to Image'), findsOneWidget);
    await goBack();

    // PDF to Word
    await tester.tap(find.text('PDF to Word'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'PDF to Word'), findsOneWidget);
    await goBack();

    // PDF to Excel
    await tester.tap(find.text('PDF to Excel'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'PDF to Excel'), findsOneWidget);
    await goBack();

    // --- Edit PDF tools ---
    // Split PDF
    await tester.tap(find.text('Split PDF'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Split PDF'), findsOneWidget);
    await goBack();

    // Compress PDF
    await tester.tap(find.text('Compress PDF'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Compress PDF'), findsOneWidget);
    await goBack();

    // Rotate PDF
    await tester.tap(find.text('Rotate PDF'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Rotate PDF'), findsOneWidget);
    await goBack();

    // Add Password
    await tester.tap(find.text('Add Password'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Add Password'), findsOneWidget);
    await goBack();

    // --- More Tools ---
    // Sign Document
    await tester.tap(find.text('Sign Document'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Sign Document'), findsOneWidget);
    // Verify the "Choose a PDF" button exists.
    expect(find.text('Choose PDF'), findsOneWidget);
    await goBack();

    // Watermark
    await tester.tap(find.text('Watermark'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Watermark'), findsOneWidget);
    expect(find.text('Choose PDF'), findsOneWidget);
    await goBack();

    // OCR
    await tester.tap(find.text('OCR'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'OCR'), findsOneWidget);
    expect(find.text('Choose image'), findsOneWidget);
    await goBack();

    // QR Code Generator (optional)
    await tester.tap(find.text('QR Code Generator'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'QR Code Generator'), findsOneWidget);
    await goBack();
  });
}
