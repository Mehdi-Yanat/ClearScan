import 'dart:io';

import 'package:path_provider/path_provider.dart';

class DocumentFolder {
  const DocumentFolder({
    required this.name,
    required this.path,
    required this.itemCount,
  });

  final String name;
  final String path;
  final int itemCount;
}

Future<Directory> _foldersDirectory() async {
  final appDirectory = await getApplicationDocumentsDirectory();
  final foldersDirectory = Directory('${appDirectory.path}/folders');
  await foldersDirectory.create(recursive: true);
  return foldersDirectory;
}

Future<List<DocumentFolder>> loadDocumentFolders() async {
  final root = await _foldersDirectory();
  final folders = <DocumentFolder>[];
  await for (final entity in root.list(followLinks: false)) {
    if (entity is! Directory) continue;
    var itemCount = 0;
    await for (final child in entity.list(followLinks: false)) {
      if (child is File) itemCount++;
    }
    folders.add(
      DocumentFolder(
        name: entity.uri.pathSegments
            .where((segment) => segment.isNotEmpty)
            .last,
        path: entity.path,
        itemCount: itemCount,
      ),
    );
  }
  folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return folders;
}

Future<void> createDocumentFolder(String name) async {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty ||
      trimmedName == '.' ||
      trimmedName == '..' ||
      trimmedName.contains(RegExp(r'[\\/:*?"<>|]'))) {
    throw const FormatException('Enter a valid folder name.');
  }

  final root = await _foldersDirectory();
  final existing = await loadDocumentFolders();
  if (existing.any(
    (folder) => folder.name.toLowerCase() == trimmedName.toLowerCase(),
  )) {
    throw const FileSystemException('A folder with this name already exists.');
  }
  await Directory('${root.path}/$trimmedName').create();
}

Future<void> deleteDocumentFolder(DocumentFolder folder) async {
  await Directory(folder.path).delete(recursive: true);
}
