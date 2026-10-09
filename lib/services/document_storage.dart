import 'dart:io';

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
