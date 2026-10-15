import 'dart:io';
import 'dart:math' as math;

import 'package:excel_community/excel_community.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:qnox_pdf_text/qnox_pdf_text.dart';

typedef PdfExcelConversionProgress = void Function(int completed, int total);

const _filesChannel = MethodChannel('com.opensource.clearscan/files');
const _excelMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
const _ocrLanguages = 'eng+deu+ara';

bool _hasText(String text) =>
    text.replaceAll(RegExp(r'[\s\u0000-\u001f]'), '').isNotEmpty;

Future<String> _extractPageTextWithOcr(String imagePath) async {
  for (final pageSegmentationMode in ['3', '6', '11']) {
    final text = await FlutterTesseractOcr.extractText(
      imagePath,
      language: _ocrLanguages,
      args: {'preserve_interword_spaces': '1', 'psm': pageSegmentationMode},
    );
    if (_hasText(text)) return text;
  }
  return '';
}

Uint8List buildPdfTextWorkbook({required List<String> pageTexts}) {
  final workbook = Excel.createExcel();
  final sheet = workbook['Extracted Text'];
  sheet.appendRow([
    TextCellValue('Page'),
    TextCellValue('Line'),
    TextCellValue('Text'),
  ]);

  var hasText = false;
  for (var pageIndex = 0; pageIndex < pageTexts.length; pageIndex++) {
    final lines = pageTexts[pageIndex]
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      sheet.appendRow([
        TextCellValue('${pageIndex + 1}'),
        TextCellValue('${lineIndex + 1}'),
        TextCellValue(lines[lineIndex]),
      ]);
      hasText = true;
    }
  }

  if (!hasText) {
    throw const FormatException(
      'No text could be extracted, including with OCR.',
    );
  }

  final bytes = workbook.encode();
  if (bytes == null || bytes.isEmpty) {
    throw StateError('Could not generate the Excel workbook.');
  }
  return Uint8List.fromList(bytes);
}

Future<File> convertPdfToExcel({
  required File pdfFile,
  required String sourceName,
  PdfExcelConversionProgress? onProgress,
}) async {
  final pdfText = QnoxPdfText();
  final pageCount = await pdfText.pageCount(pdfFile.path);
  if (pageCount < 1) {
    throw const FormatException('The selected PDF contains no pages.');
  }

  final pageTexts = <String>[];
  PdfDocument? renderer;
  Directory? temporaryOcrDirectory;
  try {
    for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      var pageText = await pdfText.extractPageText(pdfFile.path, pageIndex);
      if (!_hasText(pageText)) {
        renderer ??= await PdfDocument.openFile(pdfFile.path);
        final page = await renderer.getPage(pageIndex + 1);
        try {
          final longestSide = math.max(page.width, page.height);
          final scale = math.min(4.0, 3200 / longestSide);
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

          temporaryOcrDirectory ??= Directory(
            '${(await getTemporaryDirectory()).path}'
            '/pdf_to_excel_ocr_${DateTime.now().microsecondsSinceEpoch}',
          );
          await temporaryOcrDirectory.create(recursive: true);
          final imageFile = File(
            '${temporaryOcrDirectory.path}/page_${pageIndex + 1}.png',
          );
          await imageFile.writeAsBytes(image.bytes, flush: true);
          pageText = await _extractPageTextWithOcr(imageFile.path);
        } finally {
          await page.close();
        }
      }

      pageTexts.add(pageText);
      onProgress?.call(pageIndex + 1, pageCount);
    }
  } finally {
    try {
      if (renderer != null) await renderer.close();
    } finally {
      if (temporaryOcrDirectory != null &&
          await temporaryOcrDirectory.exists()) {
        await temporaryOcrDirectory.delete(recursive: true);
      }
    }
  }

  final excelBytes = buildPdfTextWorkbook(pageTexts: pageTexts);
  final baseName = sourceName
      .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  final safeBaseName = baseName.isEmpty ? 'document' : baseName;
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final filename = '${safeBaseName}_$timestamp.xlsx';
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final outputDirectory = Directory('${documentsDirectory.path}/pdf_to_excel');
  await outputDirectory.create(recursive: true);
  final outputFile = File('${outputDirectory.path}/$filename');
  await outputFile.writeAsBytes(excelBytes, flush: true);

  if (Platform.isAndroid) {
    final uri = await _filesChannel.invokeMethod<String>('saveToDownloads', {
      'filename': filename,
      'mimeType': _excelMimeType,
      'bytes': excelBytes,
    });
    if (uri == null || uri.isEmpty) {
      throw Exception('Android did not return the saved Excel file location.');
    }
  }

  return outputFile;
}
