import 'dart:io';

import 'package:flutter/material.dart';

class ScanPreview extends StatelessWidget {
  final File? scannedImage;
  final bool isLoading;

  const ScanPreview({
    super.key,
    required this.scannedImage,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (scannedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          scannedImage!,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.document_scanner, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No scan yet. Use the buttons below to capture and crop a document.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
