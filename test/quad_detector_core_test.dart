import 'dart:typed_data';

import 'package:clear_scan/services/imaging/quad_detector_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opencv_dart/opencv.dart' as cv;

void main() {
  group('findBestQuad', () {
    test('finds a centered rectangular document', () {
      final image = _documentImage();
      try {
        final candidate = findBestQuad(image, QuadParams.paper());

        expect(candidate, isNotNull);
        expect(candidate!.corners, hasLength(4));
        expect(candidate.areaRatio, inInclusiveRange(0.08, 0.99));
        expect(candidate.confidence, inInclusiveRange(0, 1));
      } finally {
        image.dispose();
      }
    });

    test('returns null when the frame contains no document edges', () {
      final image = cv.Mat.fromList(
        240,
        320,
        cv.MatType.CV_8UC1,
        Uint8List(320 * 240)..fillRange(0, 320 * 240, 128),
      );
      try {
        expect(findBestQuad(image, QuadParams.paper()), isNull);
      } finally {
        image.dispose();
      }
    });

    test('rejects candidates below the configured minimum area', () {
      final image = _documentImage();
      try {
        final params = QuadParams(
          minAreaRatio: 0.8,
          maxAreaRatio: 0.99,
          preferredAreaRatio: 0.9,
          minAspect: 1,
          maxAspect: 2.2,
        );

        expect(findBestQuad(image, params), isNull);
      } finally {
        image.dispose();
      }
    });

    test('rejects candidates outside the configured aspect range', () {
      final image = _documentImage();
      try {
        final params = QuadParams(
          minAreaRatio: 0.08,
          maxAreaRatio: 0.99,
          preferredAreaRatio: 0.55,
          minAspect: 1,
          maxAspect: 1.2,
        );

        expect(findBestQuad(image, params), isNull);
      } finally {
        image.dispose();
      }
    });
  });
}

cv.Mat _documentImage() {
  const width = 320;
  const height = 240;
  final pixels = Uint8List(width * height)..fillRange(0, width * height, 30);
  for (var y = 40; y < 200; y++) {
    for (var x = 40; x < 280; x++) {
      pixels[y * width + x] = 225;
    }
  }
  return cv.Mat.fromList(height, width, cv.MatType.CV_8UC1, pixels);
}
