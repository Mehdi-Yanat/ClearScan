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

Future<List<RecentDocument>> loadRecentDocuments({int limit = 4}) async {
  final documents = Platform.isAndroid
      ? await _loadAndroidDocuments()
      : await _loadLocalDocuments();
  documents.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
  return documents.take(limit).toList(growable: false);
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
        name: entry['name']! as String,
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
