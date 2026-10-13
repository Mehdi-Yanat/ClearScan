import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:printing/printing.dart';
import 'package:qnox_pdf_text/qnox_pdf_text.dart';
import 'package:share_plus/share_plus.dart';

import '../documents/document_storage.dart';

enum ShareSheetAction {
  share,
  email,
  export,
  print,
  asImages,
  asText,
  cloud,
  copyLink,
}

const _ocrLanguages = 'eng+deu+ara';

Future<void> performShareSheetAction({
  required ShareSheetAction action,
  required String fileName,
  required String fileType,
  required Future<Uint8List> Function() loadBytes,
}) async {
  final bytes = await loadBytes();
  if (bytes.isEmpty) {
    throw FormatException('Could not read $fileName.');
  }

  switch (action) {
    case ShareSheetAction.email:
      await _shareFiles(
        [(fileName, bytes)],
        subject: fileName,
        title: 'Email document',
      );
    case ShareSheetAction.print:
      final pdfBytes = fileType == 'PDF' ? bytes : await _imageToPdf(bytes);
      await Printing.layoutPdf(name: fileName, onLayout: (_) async => pdfBytes);
    case ShareSheetAction.asImages:
      if (fileType == 'PDF') {
        await _sharePdfPagesAsImages(fileName, bytes);
      } else {
        await _shareFiles([(fileName, bytes)], subject: fileName);
      }
    case ShareSheetAction.asText:
      final text = fileType == 'PDF'
          ? await _extractPdfText(fileName, bytes)
          : await _extractImageText(fileName, fileType, bytes);
      await SharePlus.instance.share(
        ShareParams(text: text, subject: fileName),
      );
    case ShareSheetAction.share:
    case ShareSheetAction.export:
    case ShareSheetAction.cloud:
    case ShareSheetAction.copyLink:
      throw ArgumentError.value(
        action,
        'action',
        'Not a share-sheet utility action',
      );
  }
}

Future<void> _sharePdfPagesAsImages(String fileName, Uint8List bytes) async {
  final tempDirectory = await _createTempDirectory();
  try {
    final document = await PdfDocument.openData(bytes);
    final files = <XFile>[];
    try {
      if (document.pagesCount < 1) {
        throw const FormatException('The PDF contains no pages.');
      }

      for (
        var pageNumber = 1;
        pageNumber <= document.pagesCount;
        pageNumber++
      ) {
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

          final pageName =
              '${_safeBaseName(fileName)}_page_'
              '${pageNumber.toString().padLeft(3, '0')}.png';
          final file = File(
            '${tempDirectory.path}${Platform.pathSeparator}$pageName',
          );
          await file.writeAsBytes(image.bytes, flush: true);
          files.add(XFile(file.path));
        } finally {
          await page.close();
        }
      }
      await SharePlus.instance.share(
        ShareParams(files: files, subject: fileName),
      );
    } finally {
      await document.close();
    }
  } finally {
    await tempDirectory.delete(recursive: true);
  }
}

Future<String> _extractPdfText(String fileName, Uint8List bytes) async {
  final tempDirectory = await _createTempDirectory();
  try {
    final pdfFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}${_safeFileName(fileName, 'pdf')}',
    );
    await pdfFile.writeAsBytes(bytes, flush: true);
    PdfDocument? renderer;
    try {
      final extractor = QnoxPdfText();
      final pageCount = await extractor.pageCount(pdfFile.path);
      if (pageCount < 1) {
        throw const FormatException('The PDF contains no pages.');
      }

      final pageTexts = <String>[];
      for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        var text = await extractor.extractPageText(pdfFile.path, pageIndex);
        if (!_hasText(text)) {
          renderer ??= await PdfDocument.openData(bytes);
          final page = await renderer.getPage(pageIndex + 1);
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
              throw Exception(
                'Could not render PDF page ${pageIndex + 1} for OCR.',
              );
            }

            final imageFile = File(
              '${tempDirectory.path}${Platform.pathSeparator}page_${pageIndex + 1}.png',
            );
            await imageFile.writeAsBytes(image.bytes, flush: true);
            text = await FlutterTesseractOcr.extractText(
              imageFile.path,
              language: _ocrLanguages,
              args: const {'preserve_interword_spaces': '1', 'psm': '3'},
            );
          } finally {
            await page.close();
          }
        }
        pageTexts.add(text.trim());
      }

      final result = pageTexts.where(_hasText).join('\n\n');
      if (!_hasText(result)) {
        throw const FormatException(
          'No text could be extracted from the document.',
        );
      }
      return result;
    } finally {
      await renderer?.close();
    }
  } finally {
    await tempDirectory.delete(recursive: true);
  }
}

Future<String> _extractImageText(
  String fileName,
  String fileType,
  Uint8List bytes,
) async {
  final tempDirectory = await _createTempDirectory();
  try {
    final extension = switch (fileType) {
      'JPG' => 'jpg',
      'PNG' => 'png',
      _ => throw FormatException(
        'Text extraction is not supported for $fileType.',
      ),
    };
    final imageFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}${_safeFileName(fileName, extension)}',
    );
    await imageFile.writeAsBytes(bytes, flush: true);
    final text = (await FlutterTesseractOcr.extractText(
      imageFile.path,
      language: _ocrLanguages,
      args: const {'preserve_interword_spaces': '1', 'psm': '3'},
    )).trim();
    if (!_hasText(text)) {
      throw const FormatException('No text could be extracted from the image.');
    }
    return text;
  } finally {
    await tempDirectory.delete(recursive: true);
  }
}

Future<Uint8List> _imageToPdf(Uint8List bytes) => createPdfFromImage(bytes);

Future<void> _shareFiles(
  List<(String, Uint8List)> namedBytes, {
  required String subject,
  String? title,
}) async {
  final tempDirectory = await _createTempDirectory();
  try {
    final files = <XFile>[];
    for (final (name, bytes) in namedBytes) {
      final file = File(
        '${tempDirectory.path}${Platform.pathSeparator}${_safeFileName(name, 'bin')}',
      );
      await file.writeAsBytes(bytes, flush: true);
      files.add(XFile(file.path));
    }
    await SharePlus.instance.share(
      ShareParams(files: files, subject: subject, title: title),
    );
  } finally {
    await tempDirectory.delete(recursive: true);
  }
}

Future<Directory> _createTempDirectory() async {
  final tempDirectory = await getTemporaryDirectory();
  final directory = Directory(
    '${tempDirectory.path}${Platform.pathSeparator}'
    'share_sheet_${DateTime.now().microsecondsSinceEpoch}',
  );
  await directory.create(recursive: true);
  return directory;
}

String _safeFileName(String fileName, String defaultExtension) {
  final sanitized = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
    return 'document.$defaultExtension';
  }
  return sanitized.contains('.') ? sanitized : '$sanitized.$defaultExtension';
}

String _safeBaseName(String fileName) {
  final sanitized = _safeFileName(fileName, 'pdf');
  final extensionIndex = sanitized.lastIndexOf('.');
  return extensionIndex > 0
      ? sanitized.substring(0, extensionIndex)
      : sanitized;
}

bool _hasText(String text) =>
    text.replaceAll(RegExp(r'[\s\u0000-\u001f]'), '').isNotEmpty;
