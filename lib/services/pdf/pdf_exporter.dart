import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

class PdfExportResult {
  final String filename;
  final String savedPath;
  final String? uri;

  const PdfExportResult({
    required this.filename,
    required this.savedPath,
    this.uri,
  });
}

Future<PdfExportResult> exportScannedImageToPdf(
  File scannedImage,
  MethodChannel platform,
) async {
  final Uint8List imageBytes = await scannedImage.readAsBytes();
  final Uint8List documentBytes = await _buildPdfBytes(imageBytes);
  final String filename =
      'scanned_document_${DateTime.now().millisecondsSinceEpoch}.pdf';

  if (Platform.isAndroid) {
    final String? uri = await _savePdfToDownloads(
      documentBytes,
      filename,
      platform,
    );
    if (uri != null) {
      return PdfExportResult(filename: filename, savedPath: uri, uri: uri);
    }
  }

  final Directory targetDir = await _resolveTargetDirectory();
  final File pdfFile = File('${targetDir.path}/$filename');
  await pdfFile.writeAsBytes(documentBytes);

  return PdfExportResult(filename: filename, savedPath: pdfFile.path);
}

Future<Uint8List> _buildPdfBytes(Uint8List imageBytes) async {
  final pw.Document document = pw.Document();
  final pw.MemoryImage pdfImage = pw.MemoryImage(imageBytes);
  final pdf.PdfPageFormat pageFormat = pdf.PdfPageFormat.a4;

  document.addPage(
    pw.Page(
      pageFormat: pageFormat,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context context) {
        return pw.Container(
          width: pageFormat.width,
          height: pageFormat.height,
          color: pdf.PdfColors.white,
          child: pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
        );
      },
    ),
  );

  return document.save();
}

Future<String?> _savePdfToDownloads(
  Uint8List documentBytes,
  String filename,
  MethodChannel platform,
) async {
  try {
    return await platform.invokeMethod('saveToDownloads', {
      'filename': filename,
      'bytes': documentBytes,
    });
  } catch (_) {
    return null;
  }
}

Future<Directory> _resolveTargetDirectory() async {
  try {
    final List<Directory>? downloads = await path_provider
        .getExternalStorageDirectories(
          type: path_provider.StorageDirectory.downloads,
        );
    if (downloads != null && downloads.isNotEmpty) {
      return downloads.first;
    }

    final Directory fallback = Directory('/storage/emulated/0/Download');
    if (await fallback.exists()) {
      return fallback;
    }
  } catch (_) {
    // ignore and fall back to application documents directory
  }

  return await path_provider.getApplicationDocumentsDirectory();
}
