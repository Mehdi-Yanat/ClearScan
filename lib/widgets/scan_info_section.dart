import 'package:flutter/material.dart';

class ScanInfoSection extends StatelessWidget {
  final String? statusMessage;

  const ScanInfoSection({super.key, required this.statusMessage});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Scan an image', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          statusMessage ??
              'Capture from camera or choose an image from gallery.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
