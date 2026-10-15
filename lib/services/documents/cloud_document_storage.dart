import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'recent_documents.dart';

const _bucketName = 'user-documents';
const _supportedExtensions = {'pdf', 'jpg', 'jpeg', 'png'};
const cloudShareLinkExpirySeconds = 24 * 60 * 60;

class CloudDocument {
  const CloudDocument({
    required this.objectPath,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String objectPath;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
}

class CloudStorageUsage {
  const CloudStorageUsage({required this.fileCount, required this.sizeBytes});

  final int fileCount;
  final int sizeBytes;
}

SupabaseClient _requireClient() {
  final client = Supabase.instance.client;
  if (client.auth.currentUser == null) {
    throw StateError('Sign in to use cloud backup.');
  }
  return client;
}

String _userPrefix(SupabaseClient client) => client.auth.currentUser!.id;

String _safeFilename(String filename) {
  final safe = filename
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  if (safe.isEmpty || safe == '.' || safe == '..') {
    throw const FormatException('Document has an invalid file name.');
  }
  final extension = safe.split('.').last.toLowerCase();
  if (!_supportedExtensions.contains(extension)) {
    throw FormatException('Unsupported cloud backup type: $filename');
  }
  return safe;
}

String _mimeType(String filename) {
  return switch (filename.split('.').last.toLowerCase()) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => throw FormatException('Unsupported document type: $filename'),
  };
}

String _displayName(String storedName) {
  final separator = storedName.indexOf('--');
  return separator >= 0 ? storedName.substring(separator + 2) : storedName;
}

Future<List<CloudDocument>> listCloudDocuments() async {
  final client = _requireClient();
  final prefix = _userPrefix(client);
  final entries = await client.storage
      .from(_bucketName)
      .list(path: prefix, searchOptions: const SearchOptions(limit: 1000));

  return entries
      .where((entry) => entry.metadata != null)
      .map((entry) {
        final size = entry.metadata?['size'];
        final sizeBytes = size is int ? size : int.tryParse('$size') ?? 0;
        return CloudDocument(
          objectPath: '$prefix/${entry.name}',
          name: _displayName(entry.name),
          sizeBytes: sizeBytes,
          modifiedAt:
              DateTime.tryParse(entry.updatedAt ?? entry.createdAt ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
        );
      })
      .toList(growable: false);
}

Future<CloudStorageUsage> loadCloudStorageUsage() async {
  final documents = await listCloudDocuments();
  return CloudStorageUsage(
    fileCount: documents.length,
    sizeBytes: documents.fold(
      0,
      (total, document) => total + document.sizeBytes,
    ),
  );
}

Future<void> uploadDocument(RecentDocument document) async {
  final name = _safeFilename(document.name);
  final bytes = await readRecentDocumentBytes(document);
  await uploadCloudFile(name: name, bytes: bytes);
}

Future<String> uploadDocumentAndCreateShareLink(RecentDocument document) async {
  final name = _safeFilename(document.name);
  final bytes = await readRecentDocumentBytes(document);
  return uploadCloudFileAndCreateShareLink(name: name, bytes: bytes);
}

Future<String> uploadCloudFile({
  required String name,
  required Uint8List bytes,
}) async {
  final client = _requireClient();
  final safeName = _safeFilename(name);
  if (bytes.isEmpty) {
    throw FormatException('Could not read $safeName.');
  }
  final objectName = '${DateTime.now().microsecondsSinceEpoch}--$safeName';
  final objectPath = '${_userPrefix(client)}/$objectName';
  await client.storage
      .from(_bucketName)
      .uploadBinary(
        objectPath,
        bytes,
        fileOptions: FileOptions(contentType: _mimeType(safeName)),
      );
  return objectPath;
}

Future<String> uploadCloudFileAndCreateShareLink({
  required String name,
  required Uint8List bytes,
}) async {
  final objectPath = await uploadCloudFile(name: name, bytes: bytes);
  return createCloudShareLink(objectPath);
}

Future<String> createCloudShareLink(String objectPath) async {
  final client = _requireClient();
  final userPrefix = _userPrefix(client);
  final pathSegments = objectPath.split('/');
  if (pathSegments.length != 2 ||
      pathSegments.first != userPrefix ||
      pathSegments.last.isEmpty) {
    throw StateError('This backup does not belong to the signed-in user.');
  }

  return client.storage
      .from(_bucketName)
      .createSignedUrl(objectPath, cloudShareLinkExpirySeconds);
}

Future<void> deleteCloudDocument(CloudDocument document) async {
  final client = _requireClient();
  final userPrefix = _userPrefix(client);
  final pathSegments = document.objectPath.split('/');
  if (pathSegments.length != 2 ||
      pathSegments.first != userPrefix ||
      pathSegments.last.isEmpty) {
    throw StateError('This backup does not belong to the signed-in user.');
  }

  await client.storage.from(_bucketName).remove([document.objectPath]);
}

Future<File> restoreCloudDocument(CloudDocument document) async {
  final client = _requireClient();
  final userPrefix = _userPrefix(client);
  if (!document.objectPath.startsWith('$userPrefix/')) {
    throw StateError('This backup does not belong to the signed-in user.');
  }

  final bytes = await client.storage
      .from(_bucketName)
      .download(document.objectPath);
  final safeName = _safeFilename(document.name);
  final appDirectory = await getApplicationDocumentsDirectory();
  final documentsDirectory = Directory(
    '${appDirectory.path}${Platform.pathSeparator}documents',
  );
  await documentsDirectory.create(recursive: true);

  var target = File(
    '${documentsDirectory.path}${Platform.pathSeparator}$safeName',
  );
  final extensionIndex = safeName.lastIndexOf('.');
  final stem = extensionIndex > 0
      ? safeName.substring(0, extensionIndex)
      : safeName;
  final extension = extensionIndex > 0
      ? safeName.substring(extensionIndex)
      : '';
  var suffix = 2;
  while (await target.exists()) {
    target = File(
      '${documentsDirectory.path}${Platform.pathSeparator}${stem}_$suffix$extension',
    );
    suffix++;
  }

  await target.writeAsBytes(Uint8List.fromList(bytes), flush: true);
  return target;
}
