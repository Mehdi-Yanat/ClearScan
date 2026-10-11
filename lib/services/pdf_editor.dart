import 'dart:ui' show Offset, Rect;
import 'dart:typed_data';

import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as renderer;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class PdfCompressionNoReductionException implements Exception {}

enum PdfEditOperation {
  split,
  compress,
  rotate,
  deletePages,
  reorderPages,
  extractPages,
  addPassword,
}

class PdfEditResult {
  const PdfEditResult({required this.suffix, required this.bytes});

  final String suffix;
  final Uint8List bytes;
}

int getPdfPageCount(Uint8List bytes, {String? password}) {
  final document = sf.PdfDocument(
    inputBytes: bytes,
    password: password?.isEmpty == true ? null : password,
  );
  try {
    final count = document.pages.count;
    if (count < 1) {
      throw const FormatException('The selected PDF contains no pages.');
    }
    return count;
  } finally {
    document.dispose();
  }
}

Uint8List signPdfBytes({
  required Uint8List inputBytes,
  required Uint8List signaturePngBytes,
  required int pageNumber,
  required Offset signaturePosition,
}) {
  final document = sf.PdfDocument(inputBytes: inputBytes);
  try {
    if (pageNumber < 1 || pageNumber > document.pages.count) {
      throw FormatException(
        'Page number must be between 1 and ${document.pages.count}.',
      );
    }

    final page = document.pages[pageNumber - 1];
    if (page.size.width <= 0 || page.size.height <= 0) {
      throw const FormatException(
        'The selected PDF page is too small to sign.',
      );
    }
    var width = page.size.width < 180 ? page.size.width : 180.0;
    final maxWidthForHeight = page.size.height * 3.6;
    if (width > maxWidthForHeight) width = maxWidthForHeight;
    var height = width / 3.6;
    final maxLeft = page.size.width - width;
    final maxTop = page.size.height - height;
    if (!signaturePosition.dx.isFinite || !signaturePosition.dy.isFinite) {
      throw const FormatException('The signature position is invalid.');
    }
    final left = signaturePosition.dx.clamp(0.0, 1.0).toDouble() * maxLeft;
    final top = signaturePosition.dy.clamp(0.0, 1.0).toDouble() * maxTop;
    page.graphics.drawImage(
      sf.PdfBitmap(signaturePngBytes),
      Rect.fromLTWH(left, top, width, height),
    );

    return Uint8List.fromList(document.saveSync());
  } finally {
    document.dispose();
  }
}

Uint8List addPdfWatermark({
  required Uint8List inputBytes,
  required String text,
  required Offset position,
  double opacity = 0.2,
}) {
  final watermarkText = text.trim();
  if (watermarkText.isEmpty) {
    throw const FormatException('Enter watermark text.');
  }
  if (!opacity.isFinite || opacity < 0 || opacity > 1) {
    throw const FormatException('Watermark opacity must be between 0 and 1.');
  }
  if (!position.dx.isFinite || !position.dy.isFinite) {
    throw const FormatException('Watermark position is invalid.');
  }

  final document = sf.PdfDocument(inputBytes: inputBytes);
  try {
    if (document.pages.count < 1) {
      throw const FormatException('The selected PDF contains no pages.');
    }

    final font = sf.PdfStandardFont(
      sf.PdfFontFamily.helvetica,
      40,
      style: sf.PdfFontStyle.bold,
    );
    for (var index = 0; index < document.pages.count; index++) {
      final page = document.pages[index];
      final graphics = page.graphics;
      final boundsWidth = page.size.width * 0.8;
      final boundsHeight = page.size.height < 64 ? page.size.height : 64.0;
      final maxLeft = page.size.width - boundsWidth;
      final maxTop = page.size.height - boundsHeight;
      final left = position.dx.clamp(0.0, 1.0).toDouble() * maxLeft;
      final top = position.dy.clamp(0.0, 1.0).toDouble() * maxTop;
      final state = graphics.save();
      try {
        graphics.setTransparency(opacity);
        graphics.drawString(
          watermarkText,
          font,
          brush: sf.PdfSolidBrush(sf.PdfColor(128, 128, 128)),
          bounds: Rect.fromLTWH(left, top, boundsWidth, boundsHeight),
          format: sf.PdfStringFormat(
            alignment: sf.PdfTextAlignment.center,
            lineAlignment: sf.PdfVerticalAlignment.middle,
          ),
        );
      } finally {
        graphics.restore(state);
      }
    }

    return Uint8List.fromList(document.saveSync());
  } finally {
    document.dispose();
  }
}

List<int> parsePdfPageRanges(String input, {required int pageCount}) {
  if (pageCount < 1) {
    throw const FormatException('The selected PDF contains no pages.');
  }
  final parts = input.split(',');
  final pages = <int>[];
  final seen = <int>{};
  for (final part in parts) {
    final match = RegExp(r'^\s*(\d+)\s*(?:-\s*(\d+)\s*)?$').firstMatch(part);
    if (match == null) {
      throw const FormatException(
        'Enter pages as comma-separated numbers or ranges, for example 1,3-5.',
      );
    }
    final first = int.parse(match.group(1)!);
    final last = int.parse(match.group(2) ?? match.group(1)!);
    if (first < 1 || last > pageCount || first > last) {
      throw FormatException('Page numbers must be between 1 and $pageCount.');
    }
    for (var page = first; page <= last; page++) {
      if (!seen.add(page)) {
        throw FormatException('Page $page is listed more than once.');
      }
      pages.add(page);
    }
  }
  if (pages.isEmpty) {
    throw const FormatException('Select at least one page.');
  }
  return pages;
}

Future<List<PdfEditResult>> editPdfBytes({
  required Uint8List inputBytes,
  required PdfEditOperation operation,
  List<int> pages = const [],
  List<int> pageOrder = const [],
  String? sourcePassword,
  String? newPassword,
}) async {
  final document = sf.PdfDocument(
    inputBytes: inputBytes,
    password: sourcePassword?.isEmpty == true ? null : sourcePassword,
  );
  try {
    final count = document.pages.count;
    if (count < 1) {
      throw const FormatException('The selected PDF contains no pages.');
    }

    switch (operation) {
      case PdfEditOperation.split:
        final selected = _validatedPages(
          pages.isEmpty ? List.generate(count, (index) => index + 1) : pages,
          count,
        );
        final results = <PdfEditResult>[];
        for (final pageNumber in selected) {
          results.add(
            PdfEditResult(
              suffix: 'page_$pageNumber',
              bytes: await _copyPages(document, [pageNumber]),
            ),
          );
        }
        return results;
      case PdfEditOperation.compress:
        final bytesToCompress = sourcePassword?.isNotEmpty == true
            ? await _copyPages(
                document,
                List.generate(count, (index) => index + 1),
              )
            : inputBytes;
        return [
          PdfEditResult(
            suffix: 'compressed',
            bytes: await _rasterCompressPdf(bytesToCompress),
          ),
        ];
      case PdfEditOperation.rotate:
        final selected = _validatedPages(pages, count);
        for (final pageNumber in selected) {
          final page = document.pages[pageNumber - 1];
          page.rotation =
              sf.PdfPageRotateAngle.values[(page.rotation.index + 1) %
                  sf.PdfPageRotateAngle.values.length];
        }
      case PdfEditOperation.deletePages:
        final selected = _validatedPages(pages, count);
        if (selected.length == count) {
          throw const FormatException(
            'A PDF must contain at least one page after editing.',
          );
        }
        for (final pageNumber in selected.reversed) {
          document.pages.removeAt(pageNumber - 1);
        }
      case PdfEditOperation.reorderPages:
        final ordered = _validatedPages(pageOrder, count);
        if (ordered.length != count) {
          throw const FormatException(
            'Reorder the complete page list without removing pages.',
          );
        }
        return [
          PdfEditResult(
            suffix: 'reordered',
            bytes: await _copyPages(document, ordered),
          ),
        ];
      case PdfEditOperation.extractPages:
        final selected = _validatedPages(pages, count);
        return [
          PdfEditResult(
            suffix: 'extracted',
            bytes: await _copyPages(document, selected),
          ),
        ];
      case PdfEditOperation.addPassword:
        final password = newPassword?.trim() ?? '';
        if (password.length < 6) {
          throw const FormatException(
            'Use a password with at least 6 characters.',
          );
        }
        document.security.algorithm = sf.PdfEncryptionAlgorithm.aesx256Bit;
        document.security.userPassword = password;
        document.security.ownerPassword = password;
    }

    return [
      PdfEditResult(
        suffix: switch (operation) {
          PdfEditOperation.compress => 'compressed',
          PdfEditOperation.rotate => 'rotated',
          PdfEditOperation.deletePages => 'pages_removed',
          PdfEditOperation.addPassword => 'protected',
          _ => throw StateError('Unexpected PDF edit operation: $operation'),
        },
        bytes: Uint8List.fromList(await document.save()),
      ),
    ];
  } finally {
    document.dispose();
  }
}

Future<Uint8List> _rasterCompressPdf(Uint8List inputBytes) async {
  final source = await renderer.PdfDocument.openData(inputBytes);
  final output = pw.Document();
  try {
    for (var pageNumber = 1; pageNumber <= source.pagesCount; pageNumber++) {
      final page = await source.getPage(pageNumber);
      try {
        final longestSide = page.width > page.height ? page.width : page.height;
        final scale = 1600 / longestSide;
        final image = await page.render(
          width: (page.width * scale).roundToDouble(),
          height: (page.height * scale).roundToDouble(),
          format: renderer.PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
          quality: 55,
        );
        if (image == null || image.bytes.isEmpty) {
          throw StateError(
            'Could not render PDF page $pageNumber to compress.',
          );
        }

        output.addPage(
          pw.Page(
            pageFormat: pdf.PdfPageFormat(page.width, page.height),
            margin: pw.EdgeInsets.zero,
            build: (_) =>
                pw.Image(pw.MemoryImage(image.bytes), fit: pw.BoxFit.fill),
          ),
        );
      } finally {
        await page.close();
      }
    }

    final compressedBytes = Uint8List.fromList(await output.save());
    if (compressedBytes.length >= inputBytes.length) {
      throw PdfCompressionNoReductionException();
    }
    return compressedBytes;
  } finally {
    await source.close();
  }
}

List<int> _validatedPages(List<int> pages, int pageCount) {
  if (pages.isEmpty) {
    throw const FormatException('Select at least one page.');
  }
  final seen = <int>{};
  for (final page in pages) {
    if (page < 1 || page > pageCount) {
      throw FormatException('Page numbers must be between 1 and $pageCount.');
    }
    if (!seen.add(page)) {
      throw FormatException('Page $page is listed more than once.');
    }
  }
  return List.unmodifiable(pages);
}

Future<Uint8List> _copyPages(
  sf.PdfDocument source,
  List<int> pageNumbers,
) async {
  final output = sf.PdfDocument();
  try {
    for (var index = 0; index < pageNumbers.length; index++) {
      final pageNumber = pageNumbers[index];
      final sourcePage = source.pages[pageNumber - 1];
      final outputPage = _addPage(output, sourcePage);
      outputPage.graphics.drawPdfTemplate(
        sourcePage.createTemplate(),
        const Offset(0, 0),
        sourcePage.size,
      );
    }
    return Uint8List.fromList(await output.save());
  } finally {
    output.dispose();
  }
}

sf.PdfPage _addPage(sf.PdfDocument output, sf.PdfPage sourcePage) {
  output.pageSettings = sf.PdfPageSettings(
    sourcePage.size,
    sourcePage.size.width > sourcePage.size.height
        ? sf.PdfPageOrientation.landscape
        : sf.PdfPageOrientation.portrait,
  )..rotate = sourcePage.rotation;
  return output.pages.add();
}
