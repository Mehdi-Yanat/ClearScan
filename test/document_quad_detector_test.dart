import 'dart:typed_data';

import 'package:clear_scan/services/imaging/document_quad_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentQuadDetector.detect', () {
    for (final ratio in [0.0, -1.0, double.infinity, double.nan]) {
      test('rejects target aspect ratio $ratio', () {
        expect(
          () => DocumentQuadDetector.detect(
            Uint8List(0),
            targetAspectRatio: ratio,
          ),
          throwsArgumentError,
        );
      });
    }
  });
}
