import 'dart:io';
import 'dart:math' as math;

import 'package:docs_gee/docs_gee.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:qnox_pdf_text/qnox_pdf_text.dart';

typedef PdfWordConversionProgress = void Function(int completed, int total);

const _filesChannel = MethodChannel('com.example.scanner/files');
const _wordDocumentMimeType =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
const _ocrLanguages = 'eng+deu+ara';

Uint8List buildEditableWordDocument({
  required List<String> pageTexts,
  required String title,
}) {
  final document = DocxDocument(title: title);
  var hasText = false;

  for (final pageText in pageTexts) {
    final lines = pageText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final isRightToLeft = RegExp(r'[\u0600-\u06ff]').hasMatch(line);
      document.addParagraph(
        DocxParagraph(
          runs: [DocxRun(line, rtl: isRightToLeft)],
          alignment: isRightToLeft ? DocxAlignment.right : DocxAlignment.left,
          pageBreakBefore: lineIndex == 0 && hasText,
          rtl: isRightToLeft,
        ),
      );
      hasText = true;
    }
  }

  if (!hasText) {
    throw const FormatException(
      'No text could be extracted, including with OCR.',
    );
  }

  return DocxGenerator().generate(document);
}

Future<File> convertPdfToWord({
  required File pdfFile,
  required String sourceName,
  PdfWordConversionProgress? onProgress,
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
      if (pageText.replaceAll(RegExp(r'[\s\u0000-\u001f]'), '').isEmpty) {
        renderer ??= await PdfDocument.openFile(pdfFile.path);
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

          temporaryOcrDirectory ??= Directory(
            '${(await getTemporaryDirectory()).path}'
            '/pdf_to_word_ocr_${DateTime.now().microsecondsSinceEpoch}',
          );
          await temporaryOcrDirectory.create(recursive: true);
          final imageFile = File(
            '${temporaryOcrDirectory.path}/page_${pageIndex + 1}.png',
          );
          await imageFile.writeAsBytes(image.bytes, flush: true);
          pageText = await FlutterTesseractOcr.extractText(
            imageFile.path,
            language: _ocrLanguages,
            args: const {'preserve_interword_spaces': '1', 'psm': '3'},
          );
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

  final title = sourceName.replaceFirst(
    RegExp(r'\.pdf$', caseSensitive: false),
    '',
  );
  final docxBytes = buildEditableWordDocument(
    pageTexts: pageTexts,
    title: title,
  );
  final baseName = sourceName
      .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  final safeBaseName = baseName.isEmpty ? 'document' : baseName;
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final filename = '${safeBaseName}_$timestamp.docx';
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final outputDirectory = Directory('${documentsDirectory.path}/pdf_to_word');
  await outputDirectory.create(recursive: true);
  final outputFile = File('${outputDirectory.path}/$filename');
  await outputFile.writeAsBytes(docxBytes, flush: true);

  if (Platform.isAndroid) {
    final uri = await _filesChannel.invokeMethod<String>('saveToDownloads', {
      'filename': filename,
      'mimeType': _wordDocumentMimeType,
      'bytes': docxBytes,
    });
    if (uri == null || uri.isEmpty) {
      throw Exception(
        'Android did not return the saved Word document location.',
      );
    }
  }

  return outputFile;
}
