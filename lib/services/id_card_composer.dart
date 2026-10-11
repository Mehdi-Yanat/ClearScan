import 'dart:typed_data';

import 'package:image/image.dart' as img;

Uint8List composeIdCardSides(List<Uint8List> sides) {
  if (sides.length != 2) {
    throw ArgumentError.value(
      sides.length,
      'sides',
      'Expected front and back.',
    );
  }

  final decodedFront = img.decodeImage(sides[0]);
  final decodedBack = img.decodeImage(sides[1]);
  if (decodedFront == null || decodedBack == null) {
    throw const FormatException('Could not read both captured document sides.');
  }

  final front = _landscape(img.bakeOrientation(decodedFront));
  final back = _landscape(img.bakeOrientation(decodedBack));
  final contentWidth = front.width > back.width ? front.width : back.width;
  final frontImage = _resizeToWidth(front, contentWidth);
  final backImage = _resizeToWidth(back, contentWidth);

  final sideMargin = (contentWidth * 0.08).round();
  final cardHeight = frontImage.height > backImage.height
      ? frontImage.height
      : backImage.height;
  final margin = (cardHeight * 0.13).round();
  final gap = (cardHeight * 0.22).round();
  final combined = img.Image(
    width: contentWidth + sideMargin * 2,
    height: frontImage.height + backImage.height + gap + margin * 2,
    numChannels: 3,
  );
  img.fill(combined, color: img.ColorRgb8(255, 255, 255));

  img.compositeImage(combined, frontImage, dstX: sideMargin, dstY: margin);
  img.compositeImage(
    combined,
    backImage,
    dstX: sideMargin,
    dstY: margin + frontImage.height + gap,
  );
  return Uint8List.fromList(img.encodeJpg(combined, quality: 95));
}

img.Image _landscape(img.Image image) =>
    image.width >= image.height ? image : img.copyRotate(image, angle: 90);

img.Image _resizeToWidth(img.Image image, int width) => image.width == width
    ? image
    : img.copyResize(
        image,
        width: width,
        interpolation: img.Interpolation.average,
      );
