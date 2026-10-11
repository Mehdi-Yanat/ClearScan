import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv.dart' as cv;

import 'card_quad_detector.dart';

enum DocumentDetectionMode { paper, card }

class DocumentQuadDetector {
  static const _maxDimension = 800;

  static Future<List<Offset>?> detect(
    Uint8List bytes, {
    double? targetAspectRatio,
    DocumentDetectionMode mode = DocumentDetectionMode.paper,
  }) {
    if (mode == DocumentDetectionMode.card) {
      return CardQuadDetector.detect(
        bytes,
        targetAspectRatio: targetAspectRatio ?? 1.586,
      );
    }
    if (targetAspectRatio != null &&
        (!targetAspectRatio.isFinite || targetAspectRatio <= 0)) {
      throw ArgumentError.value(targetAspectRatio, 'targetAspectRatio');
    }
    return compute(
      _detectPaperQuad,
      _PaperDetectionJob(bytes, targetAspectRatio),
    );
  }
}

class _PaperDetectionJob {
  const _PaperDetectionJob(this.bytes, this.targetAspectRatio);

  final Uint8List bytes;
  final double? targetAspectRatio;
}

List<Offset>? _detectPaperQuad(_PaperDetectionJob job) {
  final decoded = cv.imdecode(job.bytes, cv.IMREAD_GRAYSCALE);
  if (decoded.isEmpty) throw const FormatException('Unsupported image.');
  try {
    final scale = math.min(
      1.0,
      DocumentQuadDetector._maxDimension / math.max(decoded.cols, decoded.rows),
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
      final corners = _findPaperCandidate(working, job.targetAspectRatio);
      if (corners == null) return null;
      return [
        for (final corner in corners)
          Offset(corner.dx / working.cols, corner.dy / working.rows),
      ];
    } finally {
      working.dispose();
    }
  } finally {
    decoded.dispose();
  }
}

List<Offset>? _findPaperCandidate(cv.Mat gray, double? targetAspectRatio) {
  if (gray.cols < 64 || gray.rows < 64) return null;
  final blurred = cv.gaussianBlur(gray, (3, 3), 0);
  final edgeMaps = <cv.Mat>[];
  final contourSets = <cv.Contours>[];
  final hierarchies = <cv.VecVec4i>[];
  try {
    final median = _medianIntensity(blurred.data);
    final lowerThreshold = math.max(18.0, median * 0.62);
    final upperThreshold = math.max(lowerThreshold + 24, median * 1.38);
    edgeMaps.add(cv.canny(blurred, lowerThreshold, upperThreshold));
    edgeMaps.add(
      cv.canny(blurred, lowerThreshold * 0.78, upperThreshold * 1.18),
    );
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

    final imageArea = (gray.cols * gray.rows).toDouble();
    final candidates = <_PaperCandidate>[];
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
        final contourAreaRatio = contourArea / imageArea;
        if (contourAreaRatio < 0.06 || contourAreaRatio > 0.98) continue;

        for (final epsilon in [0.012, 0.02, 0.03, 0.045, 0.06]) {
          final polygon = cv.approxPolyDP(contour, perimeter * epsilon, true);
          try {
            if (polygon.length != 4 || !cv.isContourConvex(polygon)) continue;
            final points = _copyAndOrder(polygon);
            if (!_isConvex(points)) continue;
            final areaRatio = _polygonArea(points) / imageArea;
            if (areaRatio < 0.06 || areaRatio > 0.98) continue;
            final width =
                ((points[1] - points[0]).distance +
                    (points[2] - points[3]).distance) /
                2;
            final height =
                ((points[3] - points[0]).distance +
                    (points[2] - points[1]).distance) /
                2;
            final shortSide = math.min(width, height);
            if (shortSide < math.min(gray.cols, gray.rows) * 0.08) continue;

            final aspectRatio = math.max(width, height) / shortSide;
            final target = targetAspectRatio == null
                ? null
                : math.max(targetAspectRatio, 1 / targetAspectRatio);
            final aspectFit = target == null
                ? 1.0
                : math.exp(-0.45 * (math.log(aspectRatio / target)).abs());
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
                            0.9)
                    .clamp(0.55, 1.0);
            final score =
                math.sqrt(areaRatio) * aspectFit * solidity * centerFit;
            candidates.add(_PaperCandidate(points, score));
          } finally {
            polygon.dispose();
          }
        }
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.first.corners;
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

class _PaperCandidate {
  const _PaperCandidate(this.corners, this.score);

  final List<Offset> corners;
  final double score;
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
    if (cross.abs() < 1) return false;
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
