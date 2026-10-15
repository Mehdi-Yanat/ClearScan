import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:opencv_dart/opencv.dart' as cv;

/// Tuning for one scan mode.
class QuadParams {
  const QuadParams({
    required this.minAreaRatio,
    required this.maxAreaRatio,
    required this.preferredAreaRatio,
    required this.minAspect,
    required this.maxAspect,
    this.targetAspect,
    this.aspectSharpness = 1.0,
    this.minSupport = 0.55,
    this.minWeakestSide = 0.30,
    this.maxContoursPerMap = 10,
    this.analysisMaxDimension = 640,
    this.refine = false,
  });

  /// ID card / passport sized object.
  factory QuadParams.card(double targetAspect) => QuadParams(
    minAreaRatio: 0.02,
    maxAreaRatio: 0.82,
    preferredAreaRatio: 0.16,
    minAspect: 1.18,
    maxAspect: 2.3,
    targetAspect: targetAspect,
    aspectSharpness: 1.15,
    // Small objects: more pixels for the coarse pass, then sub-pixel refinement.
    analysisMaxDimension: 800,
    refine: true,
  );

  /// Sheet of paper or open book: large, mild aspect preference.
  factory QuadParams.paper({double? targetAspect}) => QuadParams(
    minAreaRatio: 0.08,
    maxAreaRatio: 0.99,
    preferredAreaRatio: 0.55,
    minAspect: 1.0,
    maxAspect: 2.2,
    targetAspect: targetAspect,
    aspectSharpness: 0.45,
  );

  final double minAreaRatio;
  final double maxAreaRatio;
  final double preferredAreaRatio;
  final double minAspect;
  final double maxAspect;
  final double? targetAspect;
  final double aspectSharpness;

  /// Mean fraction of sampled points along the 4 sides that touch an edge.
  final double minSupport;

  /// Same, for the weakest side (a finger may cover one side).
  final double minWeakestSide;
  final int maxContoursPerMap;

  /// Longest side of the image the coarse detector works on.
  final int analysisMaxDimension;

  /// Re-measure the four edges on the full-resolution pixels (see quad_refiner).
  final bool refine;
}

class QuadCandidate {
  const QuadCandidate(this.corners, this.areaRatio, this.confidence);

  /// Order: top-left, top-right, bottom-right, bottom-left (pixels of `gray`).
  final List<Offset> corners;
  final double areaRatio;

  /// 0..1. Roughly: >0.7 is a clean detection.
  final double confidence;
}

QuadCandidate? findBestQuad(cv.Mat gray, QuadParams p) {
  if (gray.cols < 64 || gray.rows < 64) return null;

  final owned = <cv.Mat>[];
  final contourSets = <cv.Contours>[];
  final hierarchies = <cv.VecVec4i>[];
  cv.Mat track(cv.Mat m) {
    owned.add(m);
    return m;
  }

  try {
    final blurred = track(cv.gaussianBlur(gray, (5, 5), 0));
    final kernel = track(cv.getStructuringElement(cv.MORPH_RECT, (5, 5)));

    final median = _medianIntensity(blurred.data);
    final low = math.max(14.0, median * 0.5);
    final high = math.max(low + 24, median * 1.3);

    final cannyStrong = track(cv.canny(blurred, low, high));
    // Permissive edge map: used to verify that a candidate side has a real edge.
    final cannyLoose = track(cv.canny(blurred, low * 0.6, high * 0.8));
    final closedStrong = track(
      cv.morphologyEx(cannyStrong, cv.MORPH_CLOSE, kernel, iterations: 2),
    );
    final closedLoose = track(
      cv.morphologyEx(cannyLoose, cv.MORPH_CLOSE, kernel, iterations: 2),
    );
    final (_, otsu) = cv.threshold(
      blurred,
      0,
      255,
      cv.THRESH_BINARY | cv.THRESH_OTSU,
    );
    track(otsu);
    final (_, otsuInv) = cv.threshold(
      blurred,
      0,
      255,
      cv.THRESH_BINARY_INV | cv.THRESH_OTSU,
    );
    track(otsuInv);
    final otsuClosed = track(
      cv.morphologyEx(otsu, cv.MORPH_CLOSE, kernel, iterations: 2),
    );
    final otsuInvClosed = track(
      cv.morphologyEx(otsuInv, cv.MORPH_CLOSE, kernel, iterations: 2),
    );

    final supportData = cannyLoose.data;
    final imageArea = (gray.cols * gray.rows).toDouble();
    final minDim = math.min(gray.cols, gray.rows);
    final candidates = <QuadCandidate>[];

    for (final map in [closedStrong, closedLoose, otsuClosed, otsuInvClosed]) {
      final (contours, hierarchy) = cv.findContours(
        map,
        cv.RETR_LIST,
        cv.CHAIN_APPROX_SIMPLE,
      );
      contourSets.add(contours);
      hierarchies.add(hierarchy);

      final ranked = <(int, double)>[];
      for (var i = 0; i < contours.length; i++) {
        final contour = contours[i];
        if (cv.arcLength(contour, true) < minDim * 0.2) continue;
        final ratio = cv.contourArea(contour) / imageArea;
        if (ratio < p.minAreaRatio * 0.5 || ratio > 1.0) continue;
        ranked.add((i, ratio));
      }
      ranked.sort((a, b) => b.$2.compareTo(a.$2));

      for (final entry in ranked.take(p.maxContoursPerMap)) {
        final points = _contourPoints(contours[entry.$1]);
        final candidate = _evaluate(
          points,
          gray.cols,
          gray.rows,
          supportData,
          p,
        );
        if (candidate != null) candidates.add(candidate);
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates.first;
  } finally {
    for (final c in contourSets) {
      c.dispose();
    }
    for (final h in hierarchies) {
      h.dispose();
    }
    for (final m in owned) {
      m.dispose();
    }
  }
}

// ───────────────────────── candidate evaluation ─────────────────────────

QuadCandidate? _evaluate(
  List<Offset> contourPoints,
  int cols,
  int rows,
  Uint8List edge,
  QuadParams p,
) {
  if (contourPoints.length < 4) return null;
  final hull = _convexHull(contourPoints);
  if (hull.length < 4) return null;
  final hullArea = _polygonArea(hull);
  final reduced = _reduceToQuad(hull);
  if (reduced == null) return null;

  // Extended edge intersections can land outside the frame (page partly cut off).
  final marginX = cols * 0.08;
  final marginY = rows * 0.08;
  for (final q in reduced) {
    if (q.dx < -marginX ||
        q.dx > cols - 1 + marginX ||
        q.dy < -marginY ||
        q.dy > rows - 1 + marginY) {
      return null;
    }
  }
  final points = _orderCorners([
    for (final q in reduced)
      Offset(q.dx.clamp(0.0, cols - 1.0), q.dy.clamp(0.0, rows - 1.0)),
  ]);

  final quadArea = _polygonArea(points);
  final areaRatio = quadArea / (cols * rows);
  if (areaRatio < p.minAreaRatio || areaRatio > p.maxAreaRatio) return null;
  if (!_anglesPlausible(points)) return null;

  final width =
      ((points[1] - points[0]).distance + (points[2] - points[3]).distance) / 2;
  final height =
      ((points[3] - points[0]).distance + (points[2] - points[1]).distance) / 2;
  final shortSide = math.min(width, height);
  if (shortSide < math.min(cols, rows) * 0.06) return null;
  final aspect = math.max(width, height) / shortSide;
  if (aspect < p.minAspect || aspect > p.maxAspect) return null;

  final (support, weakest) = _edgeSupport(edge, cols, rows, points);
  if (support < p.minSupport || weakest < p.minWeakestSide) return null;

  final targetAspect = p.targetAspect;
  final aspectFit = targetAspect == null
      ? 1.0
      : math.exp(
          -p.aspectSharpness *
              math.log(aspect / math.max(targetAspect, 1 / targetAspect)).abs(),
        );
  final tightness = (hullArea / math.max(1, quadArea)).clamp(0.4, 1.0);
  final centerX = points.map((q) => q.dx).reduce((a, b) => a + b) / (4 * cols);
  final centerY = points.map((q) => q.dy).reduce((a, b) => a + b) / (4 * rows);
  final centerFit =
      (1 -
              math.sqrt(
                    math.pow(centerX - 0.5, 2) + math.pow(centerY - 0.5, 2),
                  ) /
                  0.75)
          .clamp(0.0, 1.0);
  final sizeFit = math.sqrt(areaRatio / p.preferredAreaRatio).clamp(0.0, 1.0);

  var confidence =
      0.30 * aspectFit +
      0.25 * support +
      0.15 * tightness +
      0.15 * sizeFit +
      0.15 * centerFit;

  // A quad hugging all four image borders is usually the frame, not the page.
  final hugsBorder = points.every(
    (q) =>
        q.dx < cols * 0.015 ||
        q.dx > cols * 0.985 ||
        q.dy < rows * 0.015 ||
        q.dy > rows * 0.985,
  );
  if (hugsBorder) confidence *= 0.6;

  return QuadCandidate(
    [for (final q in points) Offset(q.dx / cols, q.dy / rows)],
    areaRatio,
    confidence.clamp(0.0, 1.0),
  );
}

/// Fraction of points sampled along each side that have an edge pixel within
/// [radius]. Returns (mean over sides, weakest side).
(double, double) _edgeSupport(
  Uint8List edge,
  int cols,
  int rows,
  List<Offset> quad, {
  int samples = 28,
  int radius = 3,
}) {
  var sum = 0.0;
  var worst = 1.0;
  for (var s = 0; s < 4; s++) {
    final a = quad[s];
    final b = quad[(s + 1) % 4];
    var hits = 0;
    for (var k = 0; k < samples; k++) {
      // Skip the very ends so corner rounding doesn't count against a side.
      final t = 0.04 + 0.92 * (k + 0.5) / samples;
      final cx = (a.dx + (b.dx - a.dx) * t).round();
      final cy = (a.dy + (b.dy - a.dy) * t).round();
      var hit = false;
      for (var dy = -radius; dy <= radius && !hit; dy++) {
        final y = cy + dy;
        if (y < 0 || y >= rows) continue;
        for (var dx = -radius; dx <= radius; dx++) {
          final x = cx + dx;
          if (x < 0 || x >= cols) continue;
          if (edge[y * cols + x] != 0) {
            hit = true;
            break;
          }
        }
      }
      if (hit) hits++;
    }
    final side = hits / samples;
    sum += side;
    if (side < worst) worst = side;
  }
  return (sum / 4, worst);
}

bool _anglesPlausible(List<Offset> q) {
  for (var i = 0; i < 4; i++) {
    final prev = q[(i + 3) % 4];
    final cur = q[i];
    final next = q[(i + 1) % 4];
    final u = prev - cur;
    final v = next - cur;
    final denom = u.distance * v.distance;
    if (denom < 1e-6) return false;
    final cosine = (u.dx * v.dx + u.dy * v.dy) / denom;
    // roughly 53°..127°: allows perspective, rejects slivers and kites
    if (cosine.abs() > 0.6) return false;
  }
  return true;
}

// ───────────────────────── geometry helpers ─────────────────────────

List<Offset> _contourPoints(cv.VecPoint contour) {
  final n = contour.length;
  final step = n > 600 ? (n / 600).ceil() : 1;
  final points = <Offset>[];
  for (var i = 0; i < n; i += step) {
    final point = contour[i];
    points.add(Offset(point.x.toDouble(), point.y.toDouble()));
    point.dispose();
  }
  return points;
}

/// Andrew's monotone chain.
List<Offset> _convexHull(List<Offset> input) {
  final pts = List<Offset>.of(
    input,
  )..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
  if (pts.length < 3) return pts;
  double cross(Offset o, Offset a, Offset b) =>
      (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
  final lower = <Offset>[];
  for (final p in pts) {
    while (lower.length >= 2 &&
        cross(lower[lower.length - 2], lower.last, p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }
  final upper = <Offset>[];
  for (final p in pts.reversed) {
    while (upper.length >= 2 &&
        cross(upper[upper.length - 2], upper.last, p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }
  lower.removeLast();
  upper.removeLast();
  return [...lower, ...upper];
}

/// Reduces a convex polygon to 4 vertices by repeatedly removing the edge whose
/// neighbours, extended until they meet, add the least area. Unlike
/// approxPolyDP this always returns a quad and never cuts corners inward.
List<Offset>? _reduceToQuad(List<Offset> hull) {
  var poly = List<Offset>.of(hull);
  var guard = 0;
  while (poly.length > 4 && guard++ < 500) {
    final n = poly.length;
    var bestIndex = -1;
    Offset? bestPoint;
    var bestAdded = double.infinity;
    for (var i = 0; i < n; i++) {
      final a = poly[(i - 1 + n) % n];
      final b = poly[i];
      final c = poly[(i + 1) % n];
      final d = poly[(i + 2) % n];
      final r = b - a;
      final s = c - d;
      final denom = r.dx * s.dy - r.dy * s.dx;
      if (denom.abs() < 1e-9) continue;
      final qp = d - a;
      final t = (qp.dx * s.dy - qp.dy * s.dx) / denom;
      final u = (qp.dx * r.dy - qp.dy * r.dx) / denom;
      if (t <= 1 || u <= 1) continue; // lines meet behind the polygon
      final x = Offset(a.dx + t * r.dx, a.dy + t * r.dy);
      final added = _polygonArea([b, x, c]);
      if (added < bestAdded) {
        bestAdded = added;
        bestIndex = i;
        bestPoint = x;
      }
    }
    if (bestIndex < 0 || bestPoint == null) {
      // Fallback: drop the vertex that contributes the least area.
      var smallest = double.infinity;
      var index = 0;
      for (var i = 0; i < n; i++) {
        final tri = _polygonArea([
          poly[(i - 1 + n) % n],
          poly[i],
          poly[(i + 1) % n],
        ]);
        if (tri < smallest) {
          smallest = tri;
          index = i;
        }
      }
      poly = [...poly.sublist(0, index), ...poly.sublist(index + 1)];
      continue;
    }
    final rotated = [...poly.sublist(bestIndex), ...poly.sublist(0, bestIndex)];
    poly = [bestPoint, ...rotated.sublist(2)];
  }
  return poly.length == 4 ? poly : null;
}

/// Returns corners as top-left, top-right, bottom-right, bottom-left.
List<Offset> _orderCorners(List<Offset> input) {
  final points = List<Offset>.of(input);
  final cx = points.map((p) => p.dx).reduce((a, b) => a + b) / 4;
  final cy = points.map((p) => p.dy).reduce((a, b) => a + b) / 4;
  points.sort(
    (a, b) => math
        .atan2(a.dy - cy, a.dx - cx)
        .compareTo(math.atan2(b.dy - cy, b.dx - cx)),
  );
  var first = 0;
  for (var i = 1; i < 4; i++) {
    if (points[i].dx + points[i].dy < points[first].dx + points[first].dy) {
      first = i;
    }
  }
  return [for (var i = 0; i < 4; i++) points[(first + i) % 4]];
}

double _polygonArea(List<Offset> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i++) {
    final cur = points[i];
    final next = points[(i + 1) % points.length];
    area += cur.dx * next.dy - next.dx * cur.dy;
  }
  return area.abs() / 2;
}

double _medianIntensity(Uint8List pixels) {
  final histogram = List<int>.filled(256, 0);
  var samples = 0;
  for (var i = 0; i < pixels.length; i += 4) {
    histogram[pixels[i]]++;
    samples++;
  }
  final halfway = (samples / 2).ceil();
  var total = 0;
  for (var value = 0; value < histogram.length; value++) {
    total += histogram[value];
    if (total >= halfway) return value.toDouble();
  }
  return 128;
}
