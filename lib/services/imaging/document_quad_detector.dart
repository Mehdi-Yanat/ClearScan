import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'card_quad_detector.dart';

enum DocumentDetectionMode { paper, card }

/// Detects the document outline in a still image (used by the crop screen).
/// Both modes share the same core as the live camera detection, so the crop
/// screen's initial corners match the live outline.
class DocumentQuadDetector {
  static Future<List<Offset>?> detect(
    Uint8List bytes, {
    double? targetAspectRatio,
    DocumentDetectionMode mode = DocumentDetectionMode.paper,
  }) {
    if (targetAspectRatio != null &&
        (!targetAspectRatio.isFinite || targetAspectRatio <= 0)) {
      throw ArgumentError.value(targetAspectRatio, 'targetAspectRatio');
    }
    final params = mode == DocumentDetectionMode.card
        ? QuadParams.card(targetAspectRatio ?? 1.586)
        : QuadParams.paper(targetAspect: targetAspectRatio);
    return CardQuadDetector.detect(bytes, params: params);
  }
}
