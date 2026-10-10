import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

Future<File> saveCroppedDocument({
  required String imagePath,
  required String name,
}) async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final scansDirectory = Directory('${documentsDirectory.path}/documents');
  await scansDirectory.create(recursive: true);

  final safeName = name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final destination = File('${scansDirectory.path}/${safeName}_$timestamp.jpg');
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
  final scansDirectory = Directory('${documentsDirectory.path}/documents');
  await scansDirectory.create(recursive: true);

  final safeName = name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  if (safeName.isEmpty) {
    throw const FormatException('Enter a valid document name.');
  }

  final bytes = extension == 'pdf'
      ? await _createImagePdf(imageBytes)
      : imageBytes;
  var destination = File('${scansDirectory.path}/$safeName.$extension');
  var suffix = 2;
  while (await destination.exists()) {
    destination = File('${scansDirectory.path}/${safeName}_$suffix.$extension');
    suffix++;
  }
  await destination.writeAsBytes(bytes, flush: true);
  return destination;
}

Future<Uint8List> _createImagePdf(Uint8List imageBytes) async {
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
