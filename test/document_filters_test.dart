import 'dart:typed_data';

import 'package:clear_scan/services/documents/document_filters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('makePreviewSource', () {
    test('downscales the longest side to the preview limit', () {
      final preview = img.decodeImage(
        makePreviewSource(_pngImage(1200, 600, img.ColorRgb8(40, 80, 120))),
      );

      expect(preview, isNotNull);
      expect(preview!.width, kPreviewMaxSide);
      expect(preview.height, 500);
    });

    test('does not upscale images already below the preview limit', () {
      final preview = img.decodeImage(
        makePreviewSource(_pngImage(320, 200, img.ColorRgb8(40, 80, 120))),
      );

      expect(preview, isNotNull);
      expect(preview!.width, 320);
      expect(preview.height, 200);
    });

    test('throws for unsupported image bytes', () {
      expect(
        () => makePreviewSource(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
    });
  });

  group('processDocument', () {
    test('preserves dimensions when image is below the save limit', () {
      final result = _process(
        width: 32,
        height: 18,
        filter: DocFilter.original,
      );

      expect(result.width, 32);
      expect(result.height, 18);
    });

    test('shrinks images so the longest side does not exceed maxSide', () {
      final result = _process(
        width: 40,
        height: 20,
        filter: DocFilter.original,
        maxSide: 10,
      );

      expect(result.width, 10);
      expect(result.height, 5);
    });

    test('caps saved images at the maximum save side', () {
      final result = _process(
        width: kSaveMaxSide + 24,
        height: 2,
        filter: DocFilter.original,
      );

      expect(result.width, kSaveMaxSide);
      expect(result.height, 2);
    });

    test('resizes portrait images without changing their orientation', () {
      final result = _process(
        width: 20,
        height: 40,
        filter: DocFilter.original,
        maxSide: 10,
      );

      expect(result.width, 5);
      expect(result.height, 10);
    });

    test('gray filter produces neutral grayscale pixels', () {
      final result = _process(width: 16, height: 16, filter: DocFilter.gray);
      final pixel = result.getPixel(8, 8);

      expect((pixel.r - pixel.g).abs(), lessThanOrEqualTo(2));
      expect((pixel.g - pixel.b).abs(), lessThanOrEqualTo(2));
    });

    test('black-and-white filter separates dark ink from white paper', () {
      final source = img.Image(width: 64, height: 64);
      img.fill(source, color: img.ColorRgb8(255, 255, 255));
      for (var y = 20; y <= 43; y++) {
        for (var x = 20; x <= 43; x++) {
          source.setPixelRgb(x, y, 20, 20, 20);
        }
      }
      final result = _processBytes(
        Uint8List.fromList(img.encodePng(source)),
        filter: DocFilter.bw,
      );

      expect(result.getPixel(32, 32).luminance, lessThan(40));
      expect(result.getPixel(4, 4).luminance, greaterThan(220));
    });

    test('vivid filter increases color saturation', () {
      final bytes = _pngImage(64, 64, img.ColorRgb8(180, 100, 100));
      final original = _processBytes(bytes, filter: DocFilter.original);
      final vivid = _processBytes(bytes, filter: DocFilter.vivid);
      final originalPixel = original.getPixel(32, 32);
      final vividPixel = vivid.getPixel(32, 32);
      final originalSaturation = _saturation(originalPixel);
      final vividSaturation = _saturation(vividPixel);

      expect(vividSaturation, greaterThan(originalSaturation + 10));
    });

    test('magic filter improves contrast for paper documents', () {
      final source = img.Image(width: 64, height: 64);
      img.fill(source, color: img.ColorRgb8(175, 175, 175));
      for (var y = 20; y <= 43; y++) {
        for (var x = 20; x <= 43; x++) {
          source.setPixelRgb(x, y, 100, 100, 100);
        }
      }

      final magic = _processBytes(
        Uint8List.fromList(img.encodePng(source)),
        filter: DocFilter.magic,
      );

      expect(magic.getPixel(4, 4).luminance, greaterThan(175));
      expect(magic.getPixel(32, 32).luminance, lessThan(100));
    });

    test('magic filter increases card color saturation', () {
      final bytes = _pngImage(64, 64, img.ColorRgb8(180, 100, 100));
      final original = _processBytes(bytes, filter: DocFilter.original);
      final magic = _processBytes(bytes, filter: DocFilter.magic, isCard: true);

      expect(
        _saturation(magic.getPixel(32, 32)),
        greaterThan(_saturation(original.getPixel(32, 32)) + 5),
      );
    });

    test('contrast adjustment increases tonal separation', () {
      final source = img.Image(width: 64, height: 64);
      for (var y = 0; y < source.height; y++) {
        final value = y < source.height ~/ 2 ? 100 : 156;
        for (var x = 0; x < source.width; x++) {
          source.setPixelRgb(x, y, value, value, value);
        }
      }
      final bytes = Uint8List.fromList(img.encodePng(source));
      final unchanged = _processBytes(bytes, filter: DocFilter.original);
      final highContrast = _processBytes(
        bytes,
        filter: DocFilter.original,
        contrast: 1,
      );

      expect(
        highContrast.getPixel(32, 48).luminance -
            highContrast.getPixel(32, 16).luminance,
        greaterThan(
          unchanged.getPixel(32, 48).luminance -
              unchanged.getPixel(32, 16).luminance,
        ),
      );
    });

    test('brightness adjustment brightens the output', () {
      final source = _process(
        width: 16,
        height: 16,
        filter: DocFilter.original,
      );
      final brighter = _process(
        width: 16,
        height: 16,
        filter: DocFilter.original,
        brightness: 1,
      );

      expect(
        brighter.getPixel(8, 8).luminance,
        greaterThan(source.getPixel(8, 8).luminance),
      );
    });

    test('throws for unsupported image bytes', () {
      expect(
        () => processDocument(
          EnhanceJob(
            bytes: Uint8List.fromList([1, 2, 3]),
            filter: DocFilter.original,
            brightness: 0.5,
            contrast: 0.5,
          ),
        ),
        throwsFormatException,
      );
    });
  });
}

num _saturation(img.Pixel pixel) {
  final channels = <num>[pixel.r, pixel.g, pixel.b]..sort();
  return channels.last - channels.first;
}

img.Image _process({
  required int width,
  required int height,
  required DocFilter filter,
  int maxSide = kSaveMaxSide,
  double brightness = 0.5,
}) {
  return _processBytes(
    _pngImage(width, height, img.ColorRgb8(70, 100, 130)),
    filter: filter,
    maxSide: maxSide,
    brightness: brightness,
  );
}

img.Image _processBytes(
  Uint8List bytes, {
  required DocFilter filter,
  int maxSide = kSaveMaxSide,
  double brightness = 0.5,
  double contrast = 0.5,
  bool isCard = false,
}) {
  final processedBytes = processDocument(
    EnhanceJob(
      bytes: bytes,
      filter: filter,
      brightness: brightness,
      contrast: contrast,
      isCard: isCard,
      maxSide: maxSide,
      quality: 100,
    ),
  );
  return img.decodeImage(processedBytes)!;
}

Uint8List _pngImage(int width, int height, img.Color color) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: color);
  return Uint8List.fromList(img.encodePng(image));
}
