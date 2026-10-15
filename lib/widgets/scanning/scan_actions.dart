import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScanActionButtons extends StatelessWidget {
  final File? scannedImage;
  final bool isExporting;
  final Future<void> Function(ImageSource source) onPickImage;
  final Future<void> Function() onExportPdf;

  const ScanActionButtons({
    super.key,
    required this.scannedImage,
    required this.isExporting,
    required this.onPickImage,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => onPickImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Scan with Camera'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => onPickImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library),
          label: const Text('Choose from Gallery'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (scannedImage != null) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isExporting ? null : onExportPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(isExporting ? 'Exporting PDF...' : 'Export as PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}
