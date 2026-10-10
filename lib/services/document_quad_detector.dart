import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class DocumentQuadDetector {
  static const _maxDimension = 800;

  static Future<List<Offset>?> detect(Uint8List bytes) async {
    final points = await compute(_detectQuad, bytes);
    if (points.length != 4) return null;
    return [for (final point in points) Offset(point[0], point[1])];
  }
}

List<List<double>> _detectQuad(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image');
  final scale = math.min(
    1.0,
    DocumentQuadDetector._maxDimension /
        math.max(decoded.width, decoded.height),
  );
  final source = scale < 1
      ? img.copyResize(
          decoded,
          width: (decoded.width * scale).round(),
          height: (decoded.height * scale).round(),
        )
      : decoded;
  final gray = img.grayscale(source);
  final width = gray.width;
  final height = gray.height;
  if (width < 64 || height < 64) return const [];

  final pixels = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      pixels[y * width + x] = gray.getPixel(x, y).r.toInt();
    }
  }

  const angleCount = 180;
  final rhoLimit = math.sqrt(width * width + height * height).ceil();
  final rhoStride = rhoLimit * 2 + 1;
  final accumulator = Uint16List(angleCount * rhoStride);
  final cosines = List<double>.generate(
    angleCount,
    (angle) => math.cos(angle * math.pi / 180),
  );
  final sines = List<double>.generate(
    angleCount,
    (angle) => math.sin(angle * math.pi / 180),
  );

  for (var y = 1; y < height - 1; y++) {
    final row = y * width;
    for (var x = 1; x < width - 1; x++) {
      final i = row + x;
      final gx =
          -pixels[i - width - 1] +
          pixels[i - width + 1] -
          2 * pixels[i - 1] +
          2 * pixels[i + 1] -
          pixels[i + width - 1] +
          pixels[i + width + 1];
      final gy =
          -pixels[i - width - 1] -
          2 * pixels[i - width] -
          pixels[i - width + 1] +
          pixels[i + width - 1] +
          2 * pixels[i + width] +
          pixels[i + width + 1];
      if (gx.abs() + gy.abs() < 140) continue;

      for (var angle = 0; angle < angleCount; angle++) {
        final rho = (x * cosines[angle] + y * sines[angle]).round() + rhoLimit;
        accumulator[angle * rhoStride + rho]++;
      }
    }
  }

  final minimumVotes = math.min(width, height) * 0.2;
  final peaks = <_HoughLine>[];
  for (var angle = 0; angle < angleCount; angle++) {
    final angleOffset = angle * rhoStride;
    for (var rho = 9; rho < rhoStride - 9; rho++) {
      final votes = accumulator[angleOffset + rho];
      if (votes < minimumVotes) continue;

      var isPeak = true;
      for (var angleDelta = -3; angleDelta <= 3 && isPeak; angleDelta++) {
        final neighborAngle = angle + angleDelta;
        if (neighborAngle < 0 || neighborAngle >= angleCount) continue;
        final neighborOffset = neighborAngle * rhoStride;
        for (var rhoDelta = -8; rhoDelta <= 8; rhoDelta++) {
          if (angleDelta == 0 && rhoDelta == 0) continue;
          final neighborIndex = neighborOffset + rho + rhoDelta;
          final currentIndex = angleOffset + rho;
          final neighborVotes = accumulator[neighborIndex];
          if (neighborVotes > votes ||
              (neighborVotes == votes && neighborIndex < currentIndex)) {
            isPeak = false;
            break;
          }
        }
      }
      if (!isPeak) continue;
      final line = _HoughLine(angle: angle, rho: rho - rhoLimit, votes: votes);
      peaks.add(line);
    }
  }
  peaks.sort((a, b) => b.votes.compareTo(a.votes));
  final candidates = <_HoughLine>[];
  for (final line in peaks) {
    if (candidates.any(
      (other) =>
          _angleDifference(other.angle, line.angle) <= 5 &&
          _rhoDifference(other, line) <= 12,
    )) {
      continue;
    }
    candidates.add(line);
    if (candidates.length == 36) break;
  }
  if (candidates.length < 4) return const [];

  final linePairs = <_ParallelLinePair>[];
  final minimumSeparation = math.min(width, height) * 0.18;
  for (var first = 0; first < candidates.length; first++) {
    for (var second = first + 1; second < candidates.length; second++) {
      final a = candidates[first];
      final b = candidates[second];
      if (_angleDifference(a.angle, b.angle) > 14 ||
          _rhoDifference(a, b) < minimumSeparation) {
        continue;
      }
      linePairs.add(_ParallelLinePair(a, b));
    }
  }

  List<Offset>? bestQuad;
  var bestScore = 0.0;
  for (var first = 0; first < linePairs.length; first++) {
    final pairA = linePairs[first];
    for (var second = first + 1; second < linePairs.length; second++) {
      final pairB = linePairs[second];
      if (_sharesLine(pairA, pairB)) continue;
      final angleDifference = _angleDifference(
        pairA.first.angle,
        pairB.first.angle,
      );
      if (angleDifference < 65 || angleDifference > 115) continue;

      final intersections = [
        _intersection(pairA.first, pairB.first),
        _intersection(pairA.second, pairB.first),
        _intersection(pairA.second, pairB.second),
        _intersection(pairA.first, pairB.second),
      ];
      if (intersections.any((point) => point == null)) continue;
      final points = [for (final point in intersections) point!];
      if (points.any(
        (point) =>
            point.dx < -width * 0.03 ||
            point.dx > width * 1.03 ||
            point.dy < -height * 0.03 ||
            point.dy > height * 1.03,
      )) {
        continue;
      }

      final ordered = _orderCorners(points);
      if (!_isConvex(ordered)) continue;
      final areaRatio = _polygonArea(ordered) / (width * height);
      if (areaRatio < 0.12) continue;
      final minSide = math.min(width, height) * 0.16;
      if (List.generate(
        4,
        (i) => (ordered[(i + 1) % 4] - ordered[i]).distance,
      ).any((length) => length < minSide)) {
        continue;
      }

      final voteProduct =
          pairA.first.votes *
          pairA.second.votes *
          pairB.first.votes *
          pairB.second.votes;
      final voteStrength = math.sqrt(math.sqrt(voteProduct.toDouble()));
      final orthogonality = 1 - (angleDifference - 90).abs() / 90;
      final score = voteStrength * math.sqrt(areaRatio) * orthogonality;
      if (score > bestScore) {
        bestScore = score;
        bestQuad = ordered;
      }
    }
  }

  if (bestQuad == null) return const [];
  return [
    for (final point in bestQuad)
      [(point.dx / width).clamp(0.0, 1.0), (point.dy / height).clamp(0.0, 1.0)],
  ];
}

class _HoughLine {
  const _HoughLine({
    required this.angle,
    required this.rho,
    required this.votes,
  });

  final int angle;
  final int rho;
  final int votes;

  double get radians => angle * math.pi / 180;
}

class _ParallelLinePair {
  const _ParallelLinePair(this.first, this.second);

  final _HoughLine first;
  final _HoughLine second;
}

bool _sharesLine(_ParallelLinePair first, _ParallelLinePair second) =>
    identical(first.first, second.first) ||
    identical(first.first, second.second) ||
    identical(first.second, second.first) ||
    identical(first.second, second.second);

double _angleDifference(int first, int second) {
  final difference = (first - second).abs();
  return math.min(difference, 180 - difference).toDouble();
}

double _rhoDifference(_HoughLine first, _HoughLine second) =>
    (first.angle - second.angle).abs() > 90
    ? (first.rho + second.rho).abs().toDouble()
    : (first.rho - second.rho).abs().toDouble();

Offset? _intersection(_HoughLine first, _HoughLine second) {
  final firstCos = math.cos(first.radians);
  final firstSin = math.sin(first.radians);
  final secondCos = math.cos(second.radians);
  final secondSin = math.sin(second.radians);
  final determinant = firstCos * secondSin - firstSin * secondCos;
  if (determinant.abs() < 0.1) return null;
  return Offset(
    (first.rho * secondSin - firstSin * second.rho) / determinant,
    (firstCos * second.rho - first.rho * secondCos) / determinant,
  );
}

List<Offset> _orderCorners(List<Offset> points) {
  final center = points.reduce((a, b) => a + b) / points.length.toDouble();
  final ordered = [...points]
    ..sort(
      (a, b) => math
          .atan2(a.dy - center.dy, a.dx - center.dx)
          .compareTo(math.atan2(b.dy - center.dy, b.dx - center.dx)),
    );
  final topLeftIndex = List.generate(ordered.length, (index) => index).reduce(
    (best, current) =>
        ordered[current].dx + ordered[current].dy <
            ordered[best].dx + ordered[best].dy
        ? current
        : best,
  );
  return [
    for (var i = 0; i < ordered.length; i++)
      ordered[(topLeftIndex + i) % ordered.length],
  ];
}

bool _isConvex(List<Offset> points) {
  var sign = 0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    final c = points[(i + 2) % points.length];
    final cross = (b.dx - a.dx) * (c.dy - b.dy) - (b.dy - a.dy) * (c.dx - b.dx);
    if (cross.abs() < 1) return false;
    final currentSign = cross.sign.toInt();
    if (sign != 0 && currentSign != sign) return false;
    sign = currentSign;
  }
  return true;
}

double _polygonArea(List<Offset> points) {
  var twiceArea = 0.0;
  for (var i = 0; i < points.length; i++) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    twiceArea += current.dx * next.dy - next.dx * current.dy;
  }
  return twiceArea.abs() / 2;
}
