import 'dart:typed_data';

import 'package:clear_scan/services/imaging/card_quad_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardQuadDetector.assessFrame validation', () {
    test('rejects non-positive frame dimensions', () async {
      for (final frame in [
        CardFrameInput(
          luminanceBytes: Uint8List(1),
          width: 0,
          height: 1,
          bytesPerRow: 1,
          bytesPerPixel: 1,
        ),
        CardFrameInput(
          luminanceBytes: Uint8List(1),
          width: 1,
          height: -1,
          bytesPerRow: 1,
          bytesPerPixel: 1,
        ),
      ]) {
        await expectLater(
          CardQuadDetector.assessFrame(frame, params: QuadParams.paper()),
          throwsArgumentError,
        );
      }
    });

    test('rejects non-positive row and pixel strides', () async {
      for (final frame in [
        CardFrameInput(
          luminanceBytes: Uint8List(4),
          width: 2,
          height: 2,
          bytesPerRow: 0,
          bytesPerPixel: 1,
        ),
        CardFrameInput(
          luminanceBytes: Uint8List(4),
          width: 2,
          height: 2,
          bytesPerRow: 2,
          bytesPerPixel: 0,
        ),
      ]) {
        await expectLater(
          CardQuadDetector.assessFrame(frame, params: QuadParams.paper()),
          throwsArgumentError,
        );
      }
    });

    test('rejects incomplete frame pixel data', () async {
      await expectLater(
        CardQuadDetector.assessFrame(
          CardFrameInput(
            luminanceBytes: Uint8List(3),
            width: 2,
            height: 2,
            bytesPerRow: 2,
            bytesPerPixel: 1,
          ),
          params: QuadParams.paper(),
        ),
        throwsArgumentError,
      );
    });
  });
}
