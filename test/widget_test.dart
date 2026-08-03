import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clear_scan/main.dart';

void main() {
  testWidgets('Verify MyApp renders ScannerPage', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app starts on the ScannerPage by checking for the title.
    expect(find.text('ClearScan'), findsOneWidget);
    expect(find.byType(ScannerPage), findsOneWidget);
  });
}
