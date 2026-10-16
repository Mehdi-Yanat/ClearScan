import 'dart:io';

import 'package:clear_scan/services/documents/recent_documents.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDirectory;
  late Directory documentsDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'clearscan-recent-documents-',
    );
    documentsDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}documents',
    );
    await documentsDirectory.create();
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

  test('maps supported extensions to display types', () {
    expect(_document('file.pdf').type, 'PDF');
    expect(_document('file.PNG').type, 'PNG');
    expect(_document('file.jpeg').type, 'JPG');
    expect(_document('file.jpg').type, 'JPG');
  });

  test('imports supported documents and sanitizes their names', () async {
    await importRecentDocument('  Scan: one.PDF  ', Uint8List.fromList([1, 2]));

    final imported = File(
      '${documentsDirectory.path}${Platform.pathSeparator}Scan__one.PDF',
    );
    expect(await imported.readAsBytes(), [1, 2]);
  });

  test('creates a unique filename when importing a duplicate', () async {
    await importRecentDocument('Scan.pdf', Uint8List.fromList([1]));
    await importRecentDocument('Scan.pdf', Uint8List.fromList([2]));

    final duplicate = File(
      '${documentsDirectory.path}${Platform.pathSeparator}Scan_2.pdf',
    );
    expect(await duplicate.readAsBytes(), [2]);
  });

  test('rejects empty data and unsupported file types', () async {
    await expectLater(
      importRecentDocument('Scan.pdf', Uint8List(0)),
      throwsFormatException,
    );
    await expectLater(
      importRecentDocument('Scan.txt', Uint8List.fromList([1])),
      throwsFormatException,
    );
  });

  test('loads supported local files newest first and applies limit', () async {
    final older = File(
      '${documentsDirectory.path}${Platform.pathSeparator}old.pdf',
    );
    final newer = File(
      '${documentsDirectory.path}${Platform.pathSeparator}new.png',
    );
    final unsupported = File(
      '${documentsDirectory.path}${Platform.pathSeparator}notes.txt',
    );
    await older.writeAsBytes([1]);
    await newer.writeAsBytes([2]);
    await unsupported.writeAsBytes([3]);
    final now = DateTime.now();
    await older.setLastModified(now.subtract(const Duration(minutes: 2)));
    await newer.setLastModified(now);
    await unsupported.setLastModified(now.add(const Duration(minutes: 1)));

    final recent = await loadRecentDocuments(limit: 1);

    expect(recent, hasLength(1));
    expect(recent.single.name, 'new.png');
  });

  test('renames and deletes a local document', () async {
    final source = File(
      '${documentsDirectory.path}${Platform.pathSeparator}before.pdf',
    );
    await source.writeAsBytes([1, 2]);
    final document = RecentDocument(
      name: 'before.pdf',
      path: source.path,
      sizeBytes: 2,
      modifiedAt: DateTime.now(),
    );

    await renameRecentDocument(document, 'after.pdf');
    final renamed = File(
      '${documentsDirectory.path}${Platform.pathSeparator}after.pdf',
    );
    expect(await renamed.exists(), isTrue);

    await deleteRecentDocument(
      RecentDocument(
        name: 'after.pdf',
        path: renamed.path,
        sizeBytes: 2,
        modifiedAt: DateTime.now(),
      ),
    );
    expect(await renamed.exists(), isFalse);
  });

  test('rejects invalid rename names', () async {
    final source = File(
      '${documentsDirectory.path}${Platform.pathSeparator}before.pdf',
    );
    await source.writeAsBytes([1]);
    final document = RecentDocument(
      name: 'before.pdf',
      path: source.path,
      sizeBytes: 1,
      modifiedAt: DateTime.now(),
    );

    await expectLater(
      renameRecentDocument(document, '../escape.pdf'),
      throwsFormatException,
    );
  });
}

RecentDocument _document(String name) => RecentDocument(
  name: name,
  path: name,
  sizeBytes: 0,
  modifiedAt: DateTime(2026),
);
