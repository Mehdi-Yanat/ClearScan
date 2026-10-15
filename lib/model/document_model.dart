import 'dart:math';

class DocumentCorners {
  final Point<double> topLeft;
  final Point<double> topRight;
  final Point<double> bottomRight;
  final Point<double> bottomLeft;

  DocumentCorners({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  List<Point<double>> toList() => [topLeft, topRight, bottomRight, bottomLeft];
}
