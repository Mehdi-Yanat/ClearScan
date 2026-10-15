import 'dart:typed_data';

import 'package:clear_scan/services/imaging/quad_refiner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('refineQuad', () {
    test('refines a coarse rectangle to clean high-contrast edges', () {
      const width = 128;
      const height = 128;
      final pixels = _rectanglePixels(
        width: width,
        height: height,
        left: 20,
        top: 24,
        right: 108,
        bottom: 104,
      );

      final result = refineQuad(
        pixels: pixels,
        width: width,
        height: height,
        rowStride: width,
        normalizedCorners: _coarseQuad(width, height),
      );

      expect(result, isNotNull);
      expect(result!.corners, hasLength(4));
      expect(result.inlierRatio, greaterThan(0.45));
      _expectNear(result.corners[0], const Offset(20, 24), width, height);
      _expectNear(result.corners[1], const Offset(108, 24), width, height);
      _expectNear(result.corners[2], const Offset(108, 104), width, height);
      _expectNear(result.corners[3], const Offset(20, 104), width, height);
    });

    test('supports row padding and non-unit pixel stride', () {
      const width = 128;
      const height = 128;
      const pixelStride = 2;
      const rowStride = width * pixelStride + 8;
      final pixels = _rectanglePixels(
        width: width,
        height: height,
        left: 20,
        top: 24,
        right: 108,
        bottom: 104,
        pixelStride: pixelStride,
        rowStride: rowStride,
      );

      final result = refineQuad(
        pixels: pixels,
        width: width,
        height: height,
        rowStride: rowStride,
        pixelStride: pixelStride,
        normalizedCorners: _coarseQuad(width, height),
      );

      expect(result, isNotNull);
      _expectNear(result!.corners[0], const Offset(20, 24), width, height);
    });

    test('returns null when no edges meet the contrast threshold', () {
      const width = 128;
      const height = 128;
      final pixels = Uint8List(width * height)
        ..fillRange(0, width * height, 128);

      final result = refineQuad(
        pixels: pixels,
        width: width,
        height: height,
        rowStride: width,
        normalizedCorners: _coarseQuad(width, height),
      );

      expect(result, isNull);
    });

    test('returns null for an invalid corner count', () {
      final result = refineQuad(
        pixels: Uint8List(128 * 128),
        width: 128,
        height: 128,
        rowStride: 128,
        normalizedCorners: const [Offset(0.1, 0.1), Offset(0.9, 0.1)],
      );

      expect(result, isNull);
    });

    test('returns null for an image smaller than the minimum dimensions', () {
      final result = refineQuad(
        pixels: Uint8List(15 * 128),
        width: 15,
        height: 128,
        rowStride: 15,
        normalizedCorners: const [
          Offset(0.1, 0.1),
          Offset(0.9, 0.1),
          Offset(0.9, 0.9),
          Offset(0.1, 0.9),
        ],
      );

      expect(result, isNull);
    });
  });
}

List<Offset> _coarseQuad(int width, int height) => [
  Offset(22 / width, 26 / height),
  Offset(106 / width, 26 / height),
  Offset(106 / width, 102 / height),
  Offset(22 / width, 102 / height),
];

Uint8List _rectanglePixels({
  required int width,
  required int height,
  required int left,
  required int top,
  required int right,
  required int bottom,
  int pixelStride = 1,
  int? rowStride,
}) {
  final stride = rowStride ?? width * pixelStride;
  final pixels = Uint8List(stride * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      pixels[y * stride + x * pixelStride] =
          x >= left && x < right && y >= top && y < bottom ? 220 : 20;
    }
  }
  return pixels;
}

void _expectNear(Offset normalized, Offset expected, int width, int height) {
  expect(normalized.dx * width, closeTo(expected.dx, 2));
  expect(normalized.dy * height, closeTo(expected.dy, 2));
}
