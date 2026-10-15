import 'dart:typed_data';

import 'package:clear_scan/services/imaging/id_card_composer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('composeIdCardSides', () {
    test('stacks front and back images into one JPEG', () {
      final result = img.decodeImage(
        composeIdCardSides([
          _imageBytes(100, 60, img.ColorRgb8(220, 30, 30)),
          _imageBytes(80, 50, img.ColorRgb8(30, 30, 220)),
        ]),
      );

      expect(result, isNotNull);
      expect(result!.width, 116);
      expect(result.height, greaterThan(110));
      expect(result.getPixel(58, 20).r, greaterThan(150));
      expect(result.getPixel(58, result.height - 20).b, greaterThan(150));
    });

    test('rotates portrait sides before composing them', () {
      final result = img.decodeImage(
        composeIdCardSides([
          _imageBytes(60, 100, img.ColorRgb8(220, 30, 30)),
          _imageBytes(50, 80, img.ColorRgb8(30, 30, 220)),
        ]),
      );

      expect(result, isNotNull);
      expect(result!.width, 116);
      expect(result.height, greaterThan(110));
    });

    test('uses white margins and a white gap between sides', () {
      final result = img.decodeImage(
        composeIdCardSides([
          _imageBytes(100, 60, img.ColorRgb8(220, 30, 30)),
          _imageBytes(80, 50, img.ColorRgb8(30, 30, 220)),
        ]),
      )!;

      final sideMargin = result.getPixel(2, 30);
      final gap = result.getPixel(58, 75);

      expect(sideMargin.r, greaterThan(240));
      expect(sideMargin.g, greaterThan(240));
      expect(sideMargin.b, greaterThan(240));
      expect(gap.r, greaterThan(240));
      expect(gap.g, greaterThan(240));
      expect(gap.b, greaterThan(240));
    });

    test('rejects a side count other than front and back', () {
      expect(
        () => composeIdCardSides([_imageBytes(20, 10, img.ColorRgb8(0, 0, 0))]),
        throwsArgumentError,
      );
    });

    test('rejects unreadable image data', () {
      expect(
        () => composeIdCardSides([
          Uint8List.fromList([1, 2, 3]),
          _imageBytes(20, 10, img.ColorRgb8(0, 0, 0)),
        ]),
        throwsFormatException,
      );
    });
  });
}

Uint8List _imageBytes(int width, int height, img.Color color) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: color);
  return Uint8List.fromList(img.encodePng(image));
}
