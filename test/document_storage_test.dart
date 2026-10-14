import 'dart:io';

import 'package:clear_scan/services/documents/document_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'clearscan-document-storage-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDirectory.path;
      }
      if (call.method == 'getExternalStorageDirectories') return <String>[];
      throw MissingPluginException('Unexpected method ${call.method}');
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('saves JPG with a sanitized name', () async {
    final result = await saveEnhancedDocument(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      name: '  My: Scan 1  ',
      format: 'jpg',
    );

    expect(
      result.path,
      endsWith('documents${Platform.pathSeparator}My__Scan_1.jpg'),
    );
    expect(await result.readAsBytes(), [1, 2, 3]);
  });

  test('uses a numbered filename when a document already exists', () async {
    await saveEnhancedDocument(
      imageBytes: Uint8List.fromList([1]),
      name: 'Scan',
      format: 'jpeg',
    );
    final duplicate = await saveEnhancedDocument(
      imageBytes: Uint8List.fromList([2]),
      name: 'Scan',
      format: 'JPEG',
    );

    expect(duplicate.uri.pathSegments.last, 'Scan_2.jpg');
    expect(await duplicate.readAsBytes(), [2]);
  });

  test('rejects unsupported document formats', () async {
    await expectLater(
      saveEnhancedDocument(
        imageBytes: Uint8List.fromList([1]),
        name: 'Scan',
        format: 'png',
      ),
      throwsFormatException,
    );
  });

  test('rejects names that become empty after sanitizing', () async {
    await expectLater(
      saveEnhancedDocument(
        imageBytes: Uint8List.fromList([1]),
        name: '   ',
        format: 'jpg',
      ),
      throwsFormatException,
    );
  });

  test('creates a PDF from image bytes when PDF format is selected', () async {
    final image = img.Image(width: 8, height: 8);
    img.fill(image, color: img.ColorRgb8(40, 80, 120));
    final result = await saveEnhancedDocument(
      imageBytes: Uint8List.fromList(img.encodePng(image)),
      name: 'Scan',
      format: 'pdf',
    );
    final bytes = await result.readAsBytes();

    expect(result.path, endsWith('Scan.pdf'));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
