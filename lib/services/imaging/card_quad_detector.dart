import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv.dart' as cv;

import 'quad_detector_core.dart';
import 'quad_refiner.dart';

export 'quad_detector_core.dart' show QuadParams;

class CardFrameInput {
  const CardFrameInput({
    required this.luminanceBytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final Uint8List luminanceBytes;
  final int width;
  final int height;
  final int bytesPerRow;
  final int bytesPerPixel;
}

class CardFrameAssessment {
  const CardFrameAssessment({
    required this.corners,
    required this.confidence,
    required this.areaRatio,
    required this.sharpness,
    required this.glareRatio,
    required this.brightness,
  });

  final List<Offset>? corners;
  final double confidence;
  final double areaRatio;
  final double sharpness;
  final double glareRatio;
  final double brightness;
}

/// Live-frame and still-image quad detection. Despite the name it now serves
/// every scan mode: pass [QuadParams.card] or [QuadParams.paper].
class CardQuadDetector {
  static Future<CardFrameAssessment> assessFrame(
    CardFrameInput frame, {
    required QuadParams params,
  }) async {
    if (frame.width < 1 ||
        frame.height < 1 ||
        frame.bytesPerRow < 1 ||
        frame.bytesPerPixel < 1) {
      throw ArgumentError('Invalid frame dimensions.');
    }
    final lastByte =
        (frame.height - 1) * frame.bytesPerRow +
        (frame.width - 1) * frame.bytesPerPixel;
    if (lastByte >= frame.luminanceBytes.length) {
      throw ArgumentError('Frame pixel data is incomplete.');
    }
    final result = await compute(_assessFrame, _FrameJob(frame, params));
    return CardFrameAssessment(
      corners: result[0] == 1
          ? [
              for (var i = 0; i < 4; i++)
                Offset(result[1 + 2 * i], result[2 + 2 * i]),
            ]
          : null,
      confidence: result[9],
      areaRatio: result[10],
      sharpness: result[11],
      glareRatio: result[12],
      brightness: result[13],
    );
  }

  static Future<List<Offset>?> detect(
    Uint8List imageBytes, {
    required QuadParams params,
  }) async {
    final result = await compute(_detectImage, _ImageJob(imageBytes, params));
    if (result.length != 8) return null;
    return [
      for (var i = 0; i < 4; i++) Offset(result[2 * i], result[2 * i + 1]),
    ];
  }
}

class _FrameJob {
  const _FrameJob(this.frame, this.params);

  final CardFrameInput frame;
  final QuadParams params;
}

class _ImageJob {
  const _ImageJob(this.bytes, this.params);

  final Uint8List bytes;
  final QuadParams params;
}

List<double> _assessFrame(_FrameJob job) {
  final frame = job.frame;
  final scale = math.min(
    1.0,
    job.params.analysisMaxDimension / math.max(frame.width, frame.height),
  );
  final width = math.max(1, (frame.width * scale).round());
  final height = math.max(1, (frame.height * scale).round());
  final pixels = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    final sourceY = math.min(frame.height - 1, (y / scale).floor());
    for (var x = 0; x < width; x++) {
      final sourceX = math.min(frame.width - 1, (x / scale).floor());
      pixels[y * width + x] =
          frame.luminanceBytes[sourceY * frame.bytesPerRow +
              sourceX * frame.bytesPerPixel];
    }
  }

  final gray = cv.Mat.fromList(height, width, cv.MatType.CV_8UC1, pixels);
  try {
    final candidate = findBestQuad(gray, job.params);
    // findBestQuad already returns corners normalised to 0..1.
    var normalized = candidate?.corners;
    if (normalized != null && job.params.refine) {
      // Re-measure the four edges on the full-resolution luminance plane.
      final refined = refineQuad(
        pixels: frame.luminanceBytes,
        width: frame.width,
        height: frame.height,
        rowStride: frame.bytesPerRow,
        pixelStride: frame.bytesPerPixel,
        normalizedCorners: normalized,
      );
      if (refined != null) normalized = refined.corners;
    }
    final sharpness = _sharpness(pixels, width, height, normalized);
    final glare = _glare(pixels, width, height, normalized);
    final brightness = _brightness(pixels, width, height, normalized);
    return [
      if (normalized == null) 0 else 1,
      for (var i = 0; i < 4; i++)
        if (normalized == null) ...[
          0.0,
          0.0,
        ] else ...[
          normalized[i].dx,
          normalized[i].dy,
        ],
      candidate?.confidence ?? 0,
      candidate?.areaRatio ?? 0,
      sharpness,
      glare,
      brightness,
    ];
  } finally {
    gray.dispose();
  }
}

List<double> _detectImage(_ImageJob job) {
  final decoded = cv.imdecode(job.bytes, cv.IMREAD_GRAYSCALE);
  if (decoded.isEmpty) throw const FormatException('Unsupported image.');
  try {
    final scale = math.min(
      1.0,
      job.params.analysisMaxDimension / math.max(decoded.cols, decoded.rows),
    );
    final cv.Mat working;
    if (scale < 1) {
      working = cv.resize(decoded, (
        (decoded.cols * scale).round(),
        (decoded.rows * scale).round(),
      ), interpolation: cv.INTER_AREA);
    } else {
      working = cv.Mat.fromMat(decoded);
    }
    try {
      final candidate = findBestQuad(working, job.params);
      if (candidate == null) return const [];
      var corners = candidate.corners;
      if (job.params.refine) {
        // Refine on the full-resolution decode, not the downscaled copy.
        final refined = refineQuad(
          pixels: decoded.data,
          width: decoded.cols,
          height: decoded.rows,
          rowStride: decoded.cols,
          normalizedCorners: corners,
        );
        if (refined != null) corners = refined.corners;
      }
      return [
        for (final point in corners) ...[point.dx, point.dy],
      ];
    } finally {
      working.dispose();
    }
  } finally {
    decoded.dispose();
  }
}

double _sharpness(Uint8List pixels, int width, int height, List<Offset>? quad) {
  var sum = 0.0;
  var squares = 0.0;
  var count = 0;
  for (var y = 1; y < height - 1; y += 2) {
    for (var x = 1; x < width - 1; x += 2) {
      if (quad != null && !_inside(Offset(x / width, y / height), quad)) {
        continue;
      }
      final i = y * width + x;
      final value =
          4 * pixels[i] -
          pixels[i - 1] -
          pixels[i + 1] -
          pixels[i - width] -
          pixels[i + width];
      sum += value;
      squares += value * value;
      count++;
    }
  }
  if (count == 0) return 0;
  final mean = sum / count;
  return math.max(0, squares / count - mean * mean);
}

double _glare(Uint8List pixels, int width, int height, List<Offset>? quad) {
  var bright = 0;
  var count = 0;
  for (var y = 0; y < height; y += 3) {
    for (var x = 0; x < width; x += 3) {
      if (quad != null && !_inside(Offset(x / width, y / height), quad)) {
        continue;
      }
      if (pixels[y * width + x] >= 248) bright++;
      count++;
    }
  }
  return count == 0 ? 0 : bright / count;
}

double _brightness(
  Uint8List pixels,
  int width,
  int height,
  List<Offset>? quad,
) {
  var sum = 0;
  var count = 0;
  for (var y = 0; y < height; y += 3) {
    for (var x = 0; x < width; x += 3) {
      if (quad != null && !_inside(Offset(x / width, y / height), quad)) {
        continue;
      }
      sum += pixels[y * width + x];
      count++;
    }
  }
  return count == 0 ? 0 : sum / count;
}

bool _inside(Offset point, List<Offset> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[i];
    final b = polygon[j];
    if ((a.dy > point.dy) != (b.dy > point.dy) &&
        point.dx < (b.dx - a.dx) * (point.dy - a.dy) / (b.dy - a.dy) + a.dx) {
      inside = !inside;
    }
  }
  return inside;
}
