import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clear_scan/services/imaging/card_corner_mask.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'roundCardCornerBytes preserves size and fills rounded corners',
    () async {
      final source = img.Image(width: 80, height: 48);
      img.fill(source, color: img.ColorRgb8(220, 30, 30));
      final result = await roundCardCornerBytes(
        Uint8List.fromList(img.encodePng(source)),
        radiusFraction: 0.2,
        fill: const ui.Color(0xFFFFFFFF),
        jpegQuality: 100,
      );
      final decoded = img.decodeImage(result);

      expect(decoded, isNotNull);
      expect(decoded!.width, 80);
      expect(decoded.height, 48);
      final corner = decoded.getPixel(0, 0);
      final center = decoded.getPixel(40, 24);
      expect(corner.r, greaterThan(220));
      expect(corner.g, greaterThan(220));
      expect(corner.b, greaterThan(220));
      expect(center.r, greaterThan(180));
      expect(center.g, lessThan(70));
      expect(center.b, lessThan(70));
    },
  );
}
