import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ProcessParams {
  final Uint8List bytes;
  final int quality;

  const ProcessParams(this.bytes, this.quality);
}

Future<Uint8List> _processImageBytes(ProcessParams params) async {
  final img.Image? rawImage = img.decodeImage(params.bytes);
  if (rawImage == null) {
    throw Exception('Could not decode scanned image.');
  }

  final img.Image filtered = img.grayscale(
    img.adjustColor(rawImage, contrast: 1.2, saturation: 0.0),
  );

  return Uint8List.fromList(img.encodeJpg(filtered, quality: params.quality));
}

class ImageProcessingService {
  static Future<File> processScannedImage(
    File sourceFile, {
    int quality = 92,
  }) async {
    final Uint8List bytes = await sourceFile.readAsBytes();
    final Uint8List processedBytes = await compute(
      _processImageBytes,
      ProcessParams(bytes, quality),
    );

    final Directory tempDir = Directory.systemTemp;
    final File outputFile = File(
      '${tempDir.path}/scanned_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await outputFile.writeAsBytes(processedBytes);
    return outputFile;
  }
}
