import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'recent_documents.dart';

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

Future<List<RecentDocument>> loadFolderDocuments(DocumentFolder folder) async {
  final directory = Directory(folder.path);
  if (!await directory.exists()) {
    throw FileSystemException('Folder no longer exists.', folder.path);
  }

  final documents = <RecentDocument>[];
  await for (final entity in directory.list(followLinks: false)) {
    if (entity is! File ||
        !_supportedDocumentExtensions.contains(
          entity.path.split('.').last.toLowerCase(),
        )) {
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
  documents.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
  return documents;
}

const _supportedDocumentExtensions = {'pdf', 'jpg', 'jpeg', 'png'};

Future<void> moveDocumentToFolder(
  RecentDocument document,
  DocumentFolder folder,
) async {
  final targetDirectory = Directory(folder.path);
  if (!await targetDirectory.exists()) {
    throw FileSystemException('Folder no longer exists.', folder.path);
  }

  final safeName = document.name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .trim();
  if (safeName.isEmpty || safeName == '.' || safeName == '..') {
    throw const FormatException('Document has an invalid file name.');
  }

  final extensionIndex = safeName.lastIndexOf('.');
  final stem = extensionIndex > 0
      ? safeName.substring(0, extensionIndex)
      : safeName;
  final extension = extensionIndex > 0
      ? safeName.substring(extensionIndex)
      : '';
  var destination = File('${folder.path}${Platform.pathSeparator}$safeName');
  var suffix = 2;
  while (await destination.exists()) {
    destination = File(
      '${folder.path}${Platform.pathSeparator}$stem ($suffix)$extension',
    );
    suffix++;
  }

  if (document.path.startsWith('content://')) {
    await destination.writeAsBytes(
      await readRecentDocumentBytes(document),
      flush: true,
    );
    try {
      await deleteRecentDocument(document);
    } on Exception catch (error) {
      await destination.delete();
      throw FileSystemException(
        'Could not remove the original document after copying it: $error',
        document.path,
      );
    }
    return;
  }

  final source = File(document.path);
  try {
    await source.rename(destination.path);
  } on FileSystemException {
    await source.copy(destination.path);
    try {
      await source.delete();
    } on Exception catch (error) {
      await destination.delete();
      throw FileSystemException(
        'Could not remove the original document after copying it: $error',
        document.path,
      );
    }
  }
}
