import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

typedef PdfImageConversionProgress = void Function(int completed, int total);

const _filesChannel = MethodChannel('com.opensource.clearscan/files');

Future<List<File>> convertPdfToImages({
  required File pdfFile,
  required String sourceName,
  PdfImageConversionProgress? onProgress,
}) async {
  final document = await PdfDocument.openFile(pdfFile.path);
  try {
    final pageCount = document.pagesCount;
    if (pageCount < 1) {
      throw const FormatException('The selected PDF contains no pages.');
    }

    final baseName = sourceName
        .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final safeBaseName = baseName.isEmpty ? 'document' : baseName;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final outputDirectory = Directory(
      '${documentsDirectory.path}/pdf_to_images/${safeBaseName}_$timestamp',
    );
    await outputDirectory.create(recursive: true);

    final convertedFiles = <File>[];
    for (var pageNumber = 1; pageNumber <= pageCount; pageNumber++) {
      final page = await document.getPage(pageNumber);
      try {
        final longestSide = math.max(page.width, page.height);
        final scale = math.min(2.5, 2400 / longestSide);
        final image = await page.render(
          width: math.max(1, (page.width * scale).round()).toDouble(),
          height: math.max(1, (page.height * scale).round()).toDouble(),
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        if (image == null || image.bytes.isEmpty) {
          throw Exception('Could not render PDF page $pageNumber.');
        }

        final pageLabel = pageNumber.toString().padLeft(3, '0');
        final filename = '${safeBaseName}_page_$pageLabel.png';
        final imageFile = File('${outputDirectory.path}/$filename');
        await imageFile.writeAsBytes(image.bytes, flush: true);

        if (Platform.isAndroid) {
          final uri = await _filesChannel.invokeMethod<String>(
            'saveToDownloads',
            {
              'filename': filename,
              'mimeType': 'image/png',
              'bytes': image.bytes,
            },
          );
          if (uri == null || uri.isEmpty) {
            throw Exception('Android did not return the saved image location.');
          }
        }

        convertedFiles.add(imageFile);
        onProgress?.call(pageNumber, pageCount);
      } finally {
        await page.close();
      }
    }

    return convertedFiles;
  } finally {
    await document.close();
  }
}
