import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv.dart' as cv;

/// ISO/IEC 7810 ID-1 (ID cards, credit cards): corner radius 3.18 mm on an
/// 85.6 mm long side.
const double idCardCornerRadiusFraction = 3.18 / 85.6;

/// Clips the perspective-corrected card at [imagePath] to a rounded rectangle
/// and fills the four corner wedges with [fill]. The warp maps the *sharp*
/// corners of the card, so without this step each rounded corner shows a small
/// piece of the table.
///
/// [radiusFraction] is relative to the long side of the image. The default is
/// slightly above the nominal 3.7% so the anti-aliased fringe is hidden too.
///
/// Returns the path of a new JPEG next to the input, or [imagePath] unchanged
/// if anything goes wrong (the original crop is still a valid result).
Future<String> maskCardCorners(
  String imagePath, {
  double radiusFraction = 0.04,
  ui.Color fill = const ui.Color(0xFFFFFFFF),
  int jpegQuality = 95,
}) async {
  try {
    final bytes = await File(imagePath).readAsBytes();
    final masked = await roundCardCornerBytes(
      bytes,
      radiusFraction: radiusFraction,
      fill: fill,
      jpegQuality: jpegQuality,
    );
    final base = imagePath.replaceFirst(RegExp(r'\.[^./\\]+$'), '');
    final output = File('${base}_rounded.jpg');
    await output.writeAsBytes(masked, flush: true);
    return output.path;
  } on Exception catch (error) {
    debugPrint('Card corner mask skipped: $error');
    return imagePath;
  }
}

Future<Uint8List> roundCardCornerBytes(
  Uint8List imageBytes, {
  required double radiusFraction,
  required ui.Color fill,
  int jpegQuality = 95,
}) async {
  final codec = await ui.instantiateImageCodec(imageBytes);
  ui.Image? source;
  ui.Image? rendered;
  try {
    source = (await codec.getNextFrame()).image;
    final width = source.width;
    final height = source.height;
    final radius = math.max(width, height) * radiusFraction;
    final rect = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, rect);
    canvas.drawRect(rect, ui.Paint()..color = fill);
    canvas.save();
    canvas.clipRRect(
      ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(radius)),
      doAntiAlias: true,
    );
    canvas.drawImage(source, ui.Offset.zero, ui.Paint());
    canvas.restore();

    rendered = await recorder.endRecording().toImage(width, height);
    final data = await rendered.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) throw Exception('Could not read the rendered pixels.');
    final rgba = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return await compute(
      _encodeJpeg,
      _EncodeJob(rgba, width, height, jpegQuality),
    );
  } finally {
    source?.dispose();
    rendered?.dispose();
    codec.dispose();
  }
}

class _EncodeJob {
  const _EncodeJob(this.rgba, this.width, this.height, this.quality);

  final Uint8List rgba;
  final int width;
  final int height;
  final int quality;
}

Uint8List _encodeJpeg(_EncodeJob job) {
  final rgba = cv.Mat.fromList(
    job.height,
    job.width,
    cv.MatType.CV_8UC4,
    job.rgba,
  );
  try {
    final bgr = cv.cvtColor(rgba, cv.COLOR_RGBA2BGR);
    try {
      final (ok, encoded) = cv.imencode(
        '.jpg',
        bgr,
        params: cv.VecI32.fromList([cv.IMWRITE_JPEG_QUALITY, job.quality]),
      );
      if (!ok) throw const FormatException('JPEG encoding failed.');
      return encoded;
    } finally {
      bgr.dispose();
    }
  } finally {
    rgba.dispose();
  }
}
