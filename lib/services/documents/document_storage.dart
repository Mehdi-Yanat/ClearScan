import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class SavedPdf {
  const SavedPdf({required this.filename, required this.path});

  final String filename;
  final String path;
}

const _filesChannel = MethodChannel('com.opensource.clearscan/files');

Future<File> saveCroppedDocument({
  required String imagePath,
  required String name,
}) async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final separator = Platform.pathSeparator;
  final scansDirectory = Directory(
    '${documentsDirectory.path}${separator}documents',
  );
  await scansDirectory.create(recursive: true);

  final safeName = name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final destination = File(
    '${scansDirectory.path}$separator${safeName}_$timestamp.jpg',
  );
  return File(imagePath).copy(destination.path);
}

Future<File> saveEnhancedDocument({
  required Uint8List imageBytes,
  required String name,
  required String format,
}) async {
  final extension = switch (format.toUpperCase()) {
    'PDF' => 'pdf',
    'JPG' || 'JPEG' => 'jpg',
    _ => throw FormatException('Unsupported document format: $format'),
  };
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final separator = Platform.pathSeparator;
  final scansDirectory = Directory(
    '${documentsDirectory.path}${separator}documents',
  );
  await scansDirectory.create(recursive: true);

  final safeName = name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  if (safeName.isEmpty) {
    throw const FormatException('Enter a valid document name.');
  }

  final bytes = extension == 'pdf'
      ? await createPdfFromImage(imageBytes)
      : imageBytes;
  var destination = File(
    '${scansDirectory.path}$separator$safeName.$extension',
  );
  var suffix = 2;
  while (await destination.exists()) {
    destination = File(
      '${scansDirectory.path}$separator${safeName}_$suffix.$extension',
    );
    suffix++;
  }
  await destination.writeAsBytes(bytes, flush: true);
  return destination;
}

Future<SavedPdf> saveEnhancedPdfToDevice({
  required Uint8List imageBytes,
  required String name,
}) async {
  final safeName = name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  if (safeName.isEmpty) {
    throw const FormatException('Enter a valid document name.');
  }
  final requestedFilename = safeName.toLowerCase().endsWith('.pdf')
      ? safeName
      : '$safeName.pdf';
  final pdfBytes = await createPdfFromImage(imageBytes);
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final separator = Platform.pathSeparator;
  final scansDirectory = Directory(
    '${documentsDirectory.path}${separator}documents',
  );
  await scansDirectory.create(recursive: true);

  var appCopy = File('${scansDirectory.path}$separator$requestedFilename');
  final extensionIndex = requestedFilename.lastIndexOf('.');
  final stem = requestedFilename.substring(0, extensionIndex);
  var suffix = 2;
  while (await appCopy.exists()) {
    appCopy = File('${scansDirectory.path}$separator${stem}_$suffix.pdf');
    suffix++;
  }
  await appCopy.writeAsBytes(pdfBytes, flush: true);

  if (Platform.isAndroid) {
    final filename = appCopy.uri.pathSegments.last;
    final uri = await _filesChannel.invokeMethod<String>('saveToDownloads', {
      'filename': filename,
      'bytes': pdfBytes,
    });
    if (uri == null || uri.isEmpty) {
      throw StateError('Android did not return the saved PDF location.');
    }
    return SavedPdf(filename: filename, path: uri);
  }

  return SavedPdf(filename: appCopy.uri.pathSegments.last, path: appCopy.path);
}

Future<Uint8List> createPdfFromImage(Uint8List imageBytes) async {
  final document = pw.Document();
  final image = pw.MemoryImage(imageBytes);
  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Container(
        width: PdfPageFormat.a4.width,
        height: PdfPageFormat.a4.height,
        color: PdfColors.white,
        child: pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    ),
  );
  return document.save();
}
