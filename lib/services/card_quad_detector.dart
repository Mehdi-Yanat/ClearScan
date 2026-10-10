import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv.dart' as cv;

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

class CardQuadDetector {
  static const _maxDimension = 640;

  static Future<CardFrameAssessment> assessFrame(
    CardFrameInput frame, {
    required double targetAspectRatio,
  }) async {
    if (frame.width < 1 ||
        frame.height < 1 ||
        frame.bytesPerRow < 1 ||
        frame.bytesPerPixel < 1 ||
        !targetAspectRatio.isFinite ||
        targetAspectRatio <= 0) {
      throw ArgumentError('Invalid card frame dimensions or aspect ratio.');
    }
    final lastByte =
        (frame.height - 1) * frame.bytesPerRow +
        (frame.width - 1) * frame.bytesPerPixel;
    if (lastByte >= frame.luminanceBytes.length) {
      throw ArgumentError('Card frame pixel data is incomplete.');
    }
    final result = await compute(
      _assessFrame,
      _FrameJob(frame, targetAspectRatio),
    );
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
    required double targetAspectRatio,
  }) async {
    if (!targetAspectRatio.isFinite || targetAspectRatio <= 0) {
      throw ArgumentError.value(targetAspectRatio, 'targetAspectRatio');
    }
    final result = await compute(
      _detectImage,
      _ImageJob(imageBytes, targetAspectRatio),
    );
    if (result.length != 8) return null;
    return [
      for (var i = 0; i < 4; i++) Offset(result[2 * i], result[2 * i + 1]),
    ];
  }
}

class _FrameJob {
  const _FrameJob(this.frame, this.targetAspectRatio);

  final CardFrameInput frame;
  final double targetAspectRatio;
}

class _ImageJob {
  const _ImageJob(this.bytes, this.targetAspectRatio);

  final Uint8List bytes;
  final double targetAspectRatio;
}

List<double> _assessFrame(_FrameJob job) {
  final frame = job.frame;
  final scale = math.min(
    1.0,
    CardQuadDetector._maxDimension / math.max(frame.width, frame.height),
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
    final candidate = _findBestCandidate(gray, job.targetAspectRatio);
    final corners = candidate?.corners;
    final normalized = corners == null
        ? null
        : [
            for (final point in corners)
              Offset(point.dx / width, point.dy / height),
          ];
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
    final sourceWidth = decoded.cols;
    final sourceHeight = decoded.rows;
    final scale = math.min(
      1.0,
      CardQuadDetector._maxDimension / math.max(sourceWidth, sourceHeight),
    );
    final cv.Mat working;
    if (scale < 1) {
      working = cv.resize(decoded, (
        (sourceWidth * scale).round(),
        (sourceHeight * scale).round(),
      ), interpolation: cv.INTER_AREA);
    } else {
      working = cv.Mat.fromMat(decoded);
    }
    try {
      final candidate = _findBestCandidate(working, job.targetAspectRatio);
      if (candidate == null) return const [];
      return [
        for (final point in candidate.corners) ...[
          point.dx / working.cols,
          point.dy / working.rows,
        ],
      ];
    } finally {
      working.dispose();
    }
  } finally {
    decoded.dispose();
  }
}

_CardCandidate? _findBestCandidate(cv.Mat gray, double targetAspectRatio) {
  if (gray.cols < 64 || gray.rows < 64) return null;
  final blurred = cv.gaussianBlur(gray, (3, 3), 0);
  final edgeMaps = <cv.Mat>[];
  final contourSets = <cv.Contours>[];
  final hierarchies = <cv.VecVec4i>[];
  try {
    final median = _medianIntensity(blurred.data);
    final low = math.max(18.0, median * 0.62);
    final high = math.max(low + 24, median * 1.38);
    edgeMaps.add(cv.canny(blurred, low, high));
    edgeMaps.add(cv.canny(blurred, low * 0.78, high * 1.18));
    edgeMaps.add(
      cv.adaptiveThreshold(
        blurred,
        255,
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv.THRESH_BINARY,
        31,
        8,
      ),
    );
    edgeMaps.add(
      cv.adaptiveThreshold(
        blurred,
        255,
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv.THRESH_BINARY_INV,
        31,
        8,
      ),
    );

    final candidates = <_CardCandidate>[];
    for (final edges in edgeMaps) {
      final (contours, hierarchy) = cv.findContours(
        edges,
        cv.RETR_LIST,
        cv.CHAIN_APPROX_SIMPLE,
      );
      contourSets.add(contours);
      hierarchies.add(hierarchy);
      for (var i = 0; i < contours.length; i++) {
        final contour = contours[i];
        final perimeter = cv.arcLength(contour, true);
        if (perimeter < math.min(gray.cols, gray.rows) * 0.12) continue;
        final contourArea = cv.contourArea(contour);
        final frameArea = (gray.cols * gray.rows).toDouble();
        final contourAreaRatio = contourArea / frameArea;
        if (contourAreaRatio < 0.0018 || contourAreaRatio > 0.82) continue;

        for (final epsilon in [0.014, 0.022, 0.035, 0.055, 0.075]) {
          final polygon = cv.approxPolyDP(contour, perimeter * epsilon, true);
          try {
            if (polygon.length != 4 || !cv.isContourConvex(polygon)) continue;
            final points = _copyAndOrder(polygon);
            if (!_isConvex(points)) continue;
            final areaRatio = _polygonArea(points) / frameArea;
            if (areaRatio < 0.0018 || areaRatio > 0.82) continue;
            final width =
                ((points[1] - points[0]).distance +
                    (points[2] - points[3]).distance) /
                2;
            final height =
                ((points[3] - points[0]).distance +
                    (points[2] - points[1]).distance) /
                2;
            if (math.min(width, height) <
                math.min(gray.cols, gray.rows) * 0.025) {
              continue;
            }
            final aspect = math.max(width, height) / math.min(width, height);
            if (aspect < 1.18 || aspect > 2.3) continue;
            final target = math.max(targetAspectRatio, 1 / targetAspectRatio);
            final aspectFit = math.exp(
              -1.15 * (math.log(aspect / target)).abs(),
            );
            final solidity = (contourArea / math.max(1, _polygonArea(points)))
                .clamp(0.45, 1.0);
            final centerX =
                points.map((point) => point.dx).reduce((a, b) => a + b) /
                (4 * gray.cols);
            final centerY =
                points.map((point) => point.dy).reduce((a, b) => a + b) /
                (4 * gray.rows);
            final centerFit =
                (1 -
                        math.sqrt(
                              math.pow(centerX - 0.5, 2) +
                                  math.pow(centerY - 0.5, 2),
                            ) /
                            0.72)
                    .clamp(0.0, 1.0);
            final sizeFit = (math.sqrt(areaRatio / 0.16)).clamp(0.0, 1.0);
            final score =
                0.40 * aspectFit +
                0.26 * solidity +
                0.20 * centerFit +
                0.14 * sizeFit;
            candidates.add(
              _CardCandidate(points, areaRatio, score.clamp(0.0, 1.0)),
            );
          } finally {
            polygon.dispose();
          }
        }
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates.first;
  } finally {
    for (final contours in contourSets) {
      contours.dispose();
    }
    for (final hierarchy in hierarchies) {
      hierarchy.dispose();
    }
    for (final edges in edgeMaps) {
      edges.dispose();
    }
    blurred.dispose();
  }
}

List<Offset> _copyAndOrder(cv.VecPoint polygon) {
  final points = <Offset>[];
  for (var i = 0; i < polygon.length; i++) {
    final point = polygon[i];
    points.add(Offset(point.x.toDouble(), point.y.toDouble()));
    point.dispose();
  }
  final centerX = points.map((point) => point.dx).reduce((a, b) => a + b) / 4;
  final centerY = points.map((point) => point.dy).reduce((a, b) => a + b) / 4;
  points.sort(
    (a, b) => math
        .atan2(a.dy - centerY, a.dx - centerX)
        .compareTo(math.atan2(b.dy - centerY, b.dx - centerX)),
  );
  final first = List.generate(4, (index) => index).reduce(
    (best, current) =>
        points[current].dx + points[current].dy <
            points[best].dx + points[best].dy
        ? current
        : best,
  );
  return [for (var i = 0; i < 4; i++) points[(first + i) % 4]];
}

bool _isConvex(List<Offset> points) {
  var sign = 0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % 4];
    final c = points[(i + 2) % 4];
    final cross = (b.dx - a.dx) * (c.dy - b.dy) - (b.dy - a.dy) * (c.dx - b.dx);
    if (cross == 0) return false;
    if (sign != 0 && cross.sign.toInt() != sign) return false;
    sign = cross.sign.toInt();
  }
  return true;
}

double _polygonArea(List<Offset> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i++) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.dx * next.dy - next.dx * current.dy;
  }
  return area.abs() / 2;
}

double _medianIntensity(Uint8List pixels) {
  final histogram = List<int>.filled(256, 0);
  for (var i = 0; i < pixels.length; i += 4) {
    histogram[pixels[i]]++;
  }
  final halfway = (pixels.length / 8).ceil();
  var total = 0;
  for (var value = 0; value < histogram.length; value++) {
    total += histogram[value];
    if (total >= halfway) return value.toDouble();
  }
  return 128;
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

class _CardCandidate {
  const _CardCandidate(this.corners, this.areaRatio, this.confidence);

  final List<Offset> corners;
  final double areaRatio;
  final double confidence;
}
