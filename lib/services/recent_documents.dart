import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class RecentDocument {
  const RecentDocument({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String name;
  final String path;
  final int sizeBytes;
  final DateTime modifiedAt;

  String get type {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'pdf' => 'PDF',
      'png' => 'PNG',
      'jpeg' || 'jpg' => 'JPG',
      _ => extension.toUpperCase(),
    };
  }
}

const _androidFilesChannel = MethodChannel('com.example.scanner/files');
const _supportedExtensions = {'pdf', 'jpg', 'jpeg', 'png'};

Future<Uint8List> readRecentDocumentBytes(RecentDocument document) async {
  final bytes = document.path.startsWith('content://')
      ? await _androidFilesChannel.invokeMethod<Uint8List>(
          'readDocumentBytes',
          {'uri': document.path},
        )
      : await File(document.path).readAsBytes();
  if (bytes == null || bytes.isEmpty) {
    throw FormatException('Could not read ${document.name}.');
  }
  return bytes;
}

Future<void> saveRecentDocumentToDevice(RecentDocument document) async {
  if (Platform.isAndroid && document.path.startsWith('content://')) {
    // These entries already come from the public Downloads collection.
    return;
  }

  final bytes = await readRecentDocumentBytes(document);
  final safeName = document.name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .trim();
  if (safeName.isEmpty || safeName == '.' || safeName == '..') {
    throw const FormatException('Enter a valid document name.');
  }
  if (Platform.isAndroid) {
    final extension = safeName.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
    final uri = await _androidFilesChannel.invokeMethod<String>(
      'saveToDownloads',
      {'filename': safeName, 'mimeType': mimeType, 'bytes': bytes},
    );
    if (uri == null || uri.isEmpty) {
      throw StateError('Android did not return the saved document location.');
    }
    return;
  }

  final documentsDirectory = await getApplicationDocumentsDirectory();
  final targetDirectory = Directory(
    '${documentsDirectory.path}${Platform.pathSeparator}documents',
  );
  await targetDirectory.create(recursive: true);
  var destination = File(
    '${targetDirectory.path}${Platform.pathSeparator}$safeName',
  );
  final extensionIndex = safeName.lastIndexOf('.');
  final stem = extensionIndex > 0
      ? safeName.substring(0, extensionIndex)
      : safeName;
  final extension = extensionIndex > 0
      ? safeName.substring(extensionIndex)
      : '';
  var suffix = 2;
  while (await destination.exists()) {
    destination = File(
      '${targetDirectory.path}${Platform.pathSeparator}${stem}_$suffix$extension',
    );
    suffix++;
  }
  await destination.writeAsBytes(bytes, flush: true);
}

Future<List<RecentDocument>> loadRecentDocuments({int? limit = 4}) async {
  final documents = Platform.isAndroid
      ? await _loadAndroidDocuments()
      : await _loadLocalDocuments();
  documents.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
  return limit == null
      ? documents
      : documents.take(limit).toList(growable: false);
}

Future<List<RecentDocument>> _loadAndroidDocuments() async {
  final entries = await _androidFilesChannel.invokeListMethod<Object?>(
    'getSavedDocuments',
  );
  if (entries == null) {
    throw StateError('Android document query returned no result.');
  }
  final publicDownloads = <RecentDocument>[];
  for (final entry in entries) {
    if (entry is! Map<Object?, Object?> ||
        entry['name'] is! String ||
        entry['path'] is! String ||
        entry['size'] is! int ||
        entry['modified'] is! int) {
      throw FormatException('Android document query returned invalid data.');
    }
    publicDownloads.add(
      RecentDocument(
        name: (entry['name']! as String).replaceFirst(
          RegExp(r'^scanned_document_'),
          '',
        ),
        path: entry['path']! as String,
        sizeBytes: entry['size']! as int,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(
          entry['modified']! as int,
        ),
      ),
    );
  }
  return [...publicDownloads, ...await _loadLocalDocuments()];
}

Future<List<RecentDocument>> _loadLocalDocuments() async {
  final directories = <Directory>[
    await getApplicationDocumentsDirectory(),
    ...?await getExternalStorageDirectories(type: StorageDirectory.downloads),
  ];
  final documents = <RecentDocument>[];
  final seenPaths = <String>{};

  for (final directory in directories) {
    if (!await directory.exists()) continue;
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final extension = entity.path.split('.').last.toLowerCase();
      if (!_supportedExtensions.contains(extension) ||
          !seenPaths.add(entity.path)) {
        continue;
      }
      final stat = await entity.stat();
      documents.add(
        RecentDocument(
          name: entity.uri.pathSegments.last,
          path: entity.path,
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
        ),
      );
    }
  }

  return documents;
}

Future<void> renameRecentDocument(
  RecentDocument document,
  String newName,
) async {
  final trimmedName = newName.trim();
  if (trimmedName.isEmpty ||
      RegExp(r'[/\\<>:"|?*\x00-\x1F]').hasMatch(trimmedName) ||
      trimmedName == '.' ||
      trimmedName == '..') {
    throw const FormatException('Enter a valid document name.');
  }

  if (document.path.startsWith('content://')) {
    final actualName = 'scanned_document_$trimmedName';
    final renamed = await _androidFilesChannel.invokeMethod<bool>(
      'renameDocument',
      {'uri': document.path, 'name': actualName},
    );
    if (renamed != true) throw StateError('Document was not renamed.');
    return;
  }

  final source = File(document.path);
  final destination =
      '${source.parent.path}${Platform.pathSeparator}$trimmedName';
  if (await File(destination).exists()) {
    throw FileSystemException('A document with that name already exists.');
  }
  await source.rename(destination);
}

Future<void> deleteRecentDocument(RecentDocument document) async {
  if (document.path.startsWith('content://')) {
    final deleted = await _androidFilesChannel.invokeMethod<bool>(
      'deleteDocument',
      {'uri': document.path},
    );
    if (deleted != true) throw StateError('Document was not deleted.');
    return;
  }
  await File(document.path).delete();
}

Future<void> shareRecentDocument(RecentDocument document) async {
  if (!Platform.isAndroid || !document.path.startsWith('content://')) return;
  final shared = await _androidFilesChannel.invokeMethod<bool>(
    'shareDocument',
    {'uri': document.path, 'name': document.name},
  );
  if (shared != true) throw StateError('Document was not shared.');
}
