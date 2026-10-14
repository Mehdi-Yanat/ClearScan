import 'dart:io';

import 'package:clear_scan/services/pdf/pdf_exporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'clearscan-pdf-export-',
    );
    pathProvider.setMockMethodCallHandler((call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDirectory.path;
      }
      if (call.method == 'getExternalStorageDirectories') return <String>[];
      throw MissingPluginException('Unexpected method ${call.method}');
    });
  });

  tearDown(() async {
    pathProvider.setMockMethodCallHandler(null);
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'exports a scanned image as an A4 PDF in the documents directory',
    () async {
      final image = img.Image(width: 12, height: 8);
      img.fill(image, color: img.ColorRgb8(40, 80, 120));
      final source = File(
        '${tempDirectory.path}${Platform.pathSeparator}scan.png',
      );
      await source.writeAsBytes(img.encodePng(image));

      final result = await exportScannedImageToPdf(
        source,
        const MethodChannel('test/pdf-export'),
      );

      expect(result.filename, startsWith('scanned_document_'));
      expect(result.filename, endsWith('.pdf'));
      expect(result.uri, isNull);
      expect(result.savedPath, startsWith(tempDirectory.path));
      final pdfFile = File(result.savedPath);
      expect(await pdfFile.exists(), isTrue);
      expect(
        String.fromCharCodes((await pdfFile.readAsBytes()).take(5)),
        '%PDF-',
      );
    },
  );
}
