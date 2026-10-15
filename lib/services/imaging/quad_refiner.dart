import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

/// Result of [refineQuad]. [corners] are normalised (0..1) in the same order
/// as the input: top-left, top-right, bottom-right, bottom-left.
class RefineResult {
  const RefineResult(this.corners, this.inlierRatio);

  final List<Offset> corners;

  /// Mean fraction of edge samples that agreed with the fitted line (0..1).
  final double inlierRatio;
}

/// Sub-pixel refinement of a coarse card/page quad.
///
/// For each side it samples intensity profiles perpendicular to the coarse
/// edge, finds the strongest gradient (parabola-interpolated), fits a robust
/// line through those points and finally intersects neighbouring lines.
/// This is far more precise than contour corners because it
///  * works on the full-resolution pixels, not the downscaled analysis image,
///  * ignores rounded corners (samples stay away from the corner arcs),
///  * averages ~36 measurements per side.
///
/// Returns null if the quad cannot be improved safely; keep the coarse quad.
RefineResult? refineQuad({
  required Uint8List pixels,
  required int width,
  required int height,
  required int rowStride,
  int pixelStride = 1,
  required List<Offset> normalizedCorners,
  int samplesPerSide = 36,
  double minInlierRatio = 0.45,
  double minContrast = 8,
}) {
  if (normalizedCorners.length != 4 || width < 16 || height < 16) return null;
  final luma = _Luma(pixels, width, height, rowStride, pixelStride);
  final coarse = [
    for (final c in normalizedCorners) Offset(c.dx * width, c.dy * height),
  ];
  final maxDim = math.max(width, height).toDouble();

  var shortSide = double.infinity;
  for (var i = 0; i < 4; i++) {
    shortSide = math.min(shortSide, (coarse[(i + 1) % 4] - coarse[i]).distance);
  }
  if (shortSide < 24) return null;

  // Search window either side of the coarse edge: 4% of the short side, so it
  // stays inside the card (the printed inner border of an ID is ~6% away).
  final radius = (shortSide * 0.04).clamp(3.0, 40.0);
  // Derivative baseline and tangent averaging scale with image resolution.
  final step = (maxDim / 1600).clamp(0.5, 2.0);
  final tangentRadius = (maxDim / 800).clamp(1.0, 6.0);
  final minTol = 0.6 + 0.5 * step;

  final lines = List<_Line?>.filled(4, null);
  var inlierSum = 0.0;
  for (var i = 0; i < 4; i++) {
    final fit = _fitSide(
      luma,
      coarse[i],
      coarse[(i + 1) % 4],
      radius: radius,
      step: step,
      tangentRadius: tangentRadius,
      samples: samplesPerSide,
      minContrast: minContrast,
      minTol: minTol,
    );
    if (fit == null) continue;
    final ratio = fit.$2 / samplesPerSide;
    if (ratio < minInlierRatio) continue;
    lines[i] = fit.$1;
    inlierSum += ratio;
  }
  if (lines.every((l) => l == null)) return null;

  // A side with no reliable edge (finger, glare) keeps its coarse line.
  final resolved = [
    for (var i = 0; i < 4; i++)
      lines[i] ?? _Line.through(coarse[i], coarse[(i + 1) % 4]),
  ];
  final corners = <Offset>[];
  for (var i = 0; i < 4; i++) {
    final p = _intersect(resolved[(i + 3) % 4], resolved[i]);
    if (p == null || (p - coarse[i]).distance > radius * 2.5) return null;
    corners.add(p);
  }

  if (!_isConvex(corners)) return null;
  final before = _area(coarse);
  final after = _area(corners);
  if (before <= 0 || after / before < 0.8 || after / before > 1.25) {
    return null;
  }

  return RefineResult([
    for (final c in corners)
      Offset((c.dx / width).clamp(0.0, 1.0), (c.dy / height).clamp(0.0, 1.0)),
  ], inlierSum / 4);
}

// ───────────────────────────── internals ─────────────────────────────

class _Luma {
  const _Luma(
    this.data,
    this.width,
    this.height,
    this.rowStride,
    this.pixelStride,
  );

  final Uint8List data;
  final int width;
  final int height;
  final int rowStride;
  final int pixelStride;

  double _at(int x, int y) => data[y * rowStride + x * pixelStride].toDouble();

  /// Bilinear sample, coordinates clamped to the image.
  double sample(double x, double y) {
    final cx = x.clamp(0.0, width - 1.001);
    final cy = y.clamp(0.0, height - 1.001);
    final x0 = cx.floor();
    final y0 = cy.floor();
    final fx = cx - x0;
    final fy = cy - y0;
    return _at(x0, y0) * (1 - fx) * (1 - fy) +
        _at(x0 + 1, y0) * fx * (1 - fy) +
        _at(x0, y0 + 1) * (1 - fx) * fy +
        _at(x0 + 1, y0 + 1) * fx * fy;
  }
}

class _Line {
  const _Line(this.cx, this.cy, this.ux, this.uy);

  factory _Line.through(Offset a, Offset b) {
    final d = b - a;
    final len = math.max(1e-9, d.distance);
    return _Line(a.dx, a.dy, d.dx / len, d.dy / len);
  }

  final double cx;
  final double cy;
  final double ux;
  final double uy;

  double distance(Offset p) => ((p.dx - cx) * -uy + (p.dy - cy) * ux).abs();
}

(_Line, int)? _fitSide(
  _Luma luma,
  Offset a,
  Offset b, {
  required double radius,
  required double step,
  required double tangentRadius,
  required int samples,
  required double minContrast,
  required double minTol,
}) {
  final dir = b - a;
  final len = dir.distance;
  if (len < 8) return null;
  final u = dir / len;
  final n = Offset(-u.dy, u.dx);

  final ds = step * 0.5;
  final m = (radius / ds).floor();
  if (m < 3) return null;
  const taps = [-1.0, -0.5, 0.0, 0.5, 1.0];
  // profile[j + m + 2] is the smoothed intensity at offset j * ds from the edge.
  final profile = List<double>.filled(2 * m + 5, 0);
  double derivative(int j) => profile[j + m + 4] - profile[j + m];

  final points = <Offset>[];
  final signs = <int>[];
  for (var k = 0; k < samples; k++) {
    // Stay away from the corners: rounded corners would bias the line.
    final t = 0.12 + 0.76 * (k + 0.5) / samples;
    final mid = a + dir * t;
    for (var j = -m - 2; j <= m + 2; j++) {
      final base = mid + n * (j * ds);
      var acc = 0.0;
      for (final tap in taps) {
        final q = base + u * (tap * tangentRadius);
        acc += luma.sample(q.dx, q.dy);
      }
      profile[j + m + 2] = acc / taps.length;
    }
    var best = 0;
    var bestAbs = 0.0;
    for (var j = -m; j <= m; j++) {
      final d = derivative(j).abs();
      if (d > bestAbs) {
        bestAbs = d;
        best = j;
      }
    }
    // Peak on the window border means the real edge is further away: skip.
    if (bestAbs < minContrast || best <= -m || best >= m) continue;
    final y0 = derivative(best).abs();
    final ym = derivative(best - 1).abs();
    final yp = derivative(best + 1).abs();
    final denom = ym - 2 * y0 + yp;
    final offset = denom.abs() > 1e-9
        ? (0.5 * (ym - yp) / denom).clamp(-1.0, 1.0)
        : 0.0;
    points.add(mid + n * ((best + offset) * ds));
    signs.add(derivative(best) >= 0 ? 1 : -1);
  }
  if (points.length < 6) return null;

  // The card is consistently lighter or darker than the background across a
  // side; drop samples that picked up an edge of the opposite polarity.
  final positives = signs.where((s) => s > 0).length;
  final keepSign = positives * 2 >= signs.length ? 1 : -1;
  final kept = [
    for (var i = 0; i < points.length; i++)
      if (signs[i] == keepSign) points[i],
  ];
  if (kept.length < 6) return null;

  var working = kept;
  var line = _fitLine(working, dir);
  for (var iter = 0; iter < 4; iter++) {
    final residuals = [for (final p in kept) line.distance(p)];
    final sorted = List<double>.of(residuals)..sort();
    final tol = math.max(minTol, 2.5 * sorted[sorted.length ~/ 2]);
    final next = [
      for (var i = 0; i < kept.length; i++)
        if (residuals[i] <= tol) kept[i],
    ];
    if (next.length < 6) break;
    working = next;
    line = _fitLine(working, dir);
  }
  final inliers = kept.where((p) => line.distance(p) <= minTol * 1.5).length;
  return (line, inliers);
}

/// Total least squares line through [pts], oriented along [hint].
_Line _fitLine(List<Offset> pts, Offset hint) {
  var mx = 0.0;
  var my = 0.0;
  for (final p in pts) {
    mx += p.dx;
    my += p.dy;
  }
  mx /= pts.length;
  my /= pts.length;
  var sxx = 0.0;
  var sxy = 0.0;
  var syy = 0.0;
  for (final p in pts) {
    final dx = p.dx - mx;
    final dy = p.dy - my;
    sxx += dx * dx;
    sxy += dx * dy;
    syy += dy * dy;
  }
  final angle = 0.5 * math.atan2(2 * sxy, sxx - syy);
  var ux = math.cos(angle);
  var uy = math.sin(angle);
  if (ux * hint.dx + uy * hint.dy < 0) {
    ux = -ux;
    uy = -uy;
  }
  return _Line(mx, my, ux, uy);
}

Offset? _intersect(_Line l1, _Line l2) {
  final cross = l1.ux * l2.uy - l1.uy * l2.ux;
  // Adjacent sides of a card are near-perpendicular; reject near-parallel pairs.
  if (cross.abs() < 0.35) return null;
  final dx = l2.cx - l1.cx;
  final dy = l2.cy - l1.cy;
  final t = (dx * l2.uy - dy * l2.ux) / cross;
  return Offset(l1.cx + t * l1.ux, l1.cy + t * l1.uy);
}

double _area(List<Offset> p) {
  var a = 0.0;
  for (var i = 0; i < p.length; i++) {
    final c = p[i];
    final n = p[(i + 1) % p.length];
    a += c.dx * n.dy - n.dx * c.dy;
  }
  return a.abs() / 2;
}

bool _isConvex(List<Offset> p) {
  var sign = 0;
  for (var i = 0; i < p.length; i++) {
    final a = p[i];
    final b = p[(i + 1) % p.length];
    final c = p[(i + 2) % p.length];
    final cross = (b.dx - a.dx) * (c.dy - b.dy) - (b.dy - a.dy) * (c.dx - b.dx);
    if (cross.abs() < 1e-6) return false;
    final s = cross > 0 ? 1 : -1;
    if (sign != 0 && s != sign) return false;
    sign = s;
  }
  return true;
}
