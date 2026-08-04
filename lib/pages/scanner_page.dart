import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../services/image_processing.dart';
import '../services/pdf_exporter.dart';
import '../widgets/scan_actions.dart';
import '../widgets/scan_info_section.dart';
import '../widgets/scan_preview.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final ImagePicker _picker = ImagePicker();
  static const MethodChannel _platform = MethodChannel(
    'com.example.scanner/files',
  );

  File? _scannedImage;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _statusMessage;

  Future<void> _pickAndCropImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Waiting for image...';
    });

    final Color toolbarColor = Theme.of(context).colorScheme.primary;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        setState(() {
          _statusMessage = 'No image selected.';
          _isLoading = false;
        });
        return;
      }

      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Document',
              toolbarColor: toolbarColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.ratio4x3,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Document',
              resetButtonHidden: false,
              aspectRatioLockEnabled: false,
            ),
          ],
        );
      } catch (_) {
        final File fallbackProcessed =
            await ImageProcessingService.processScannedImage(
              File(pickedFile.path),
            );
        setState(() {
          _scannedImage = fallbackProcessed;
          _statusMessage = 'Crop failed; used original image.';
          _isLoading = false;
        });
        return;
      }

      if (croppedFile == null) {
        setState(() {
          _statusMessage = 'Crop canceled.';
          _isLoading = false;
        });
        return;
      }

      final File processedImage =
          await ImageProcessingService.processScannedImage(
            File(croppedFile.path),
          );

      setState(() {
        _scannedImage = processedImage;
        _statusMessage = 'Scan complete. Preview below.';
      });
    } catch (error) {
      setState(() {
        _statusMessage = 'Failed to scan image: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_scannedImage == null) {
      setState(() {
        _statusMessage = 'No scanned image available to export.';
      });
      return;
    }

    setState(() {
      _isExporting = true;
      _statusMessage = 'Exporting scanned image to PDF...';
    });

    try {
      final PdfExportResult result = await exportScannedImageToPdf(
        _scannedImage!,
        _platform,
      );

      setState(() {
        _statusMessage = 'PDF saved as ${result.filename}';
      });

      if (!mounted) return;
      _showPdfSnackBar(
        'Saved PDF as ${result.filename}',
        uri: result.uri ?? result.savedPath,
      );
    } catch (error) {
      setState(() {
        _statusMessage = 'PDF export failed: $error';
      });
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showPdfSnackBar(String message, {required String uri}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () async {
            try {
              await _platform.invokeMethod('openUri', {'uri': uri});
            } catch (_) {
              // Best effort only.
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClearScan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: OrientationBuilder(
            builder: (context, orientation) {
              final bool isLandscape = orientation == Orientation.landscape;
              if (isLandscape) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScanInfoSection(statusMessage: _statusMessage),
                          Expanded(
                            child: ScanPreview(
                              scannedImage: _scannedImage,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                          ScanActionButtons(
                            scannedImage: _scannedImage,
                            isExporting: _isExporting,
                            onPickImage: _pickAndCropImage,
                            onExportPdf: _exportPdf,
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScanInfoSection(statusMessage: _statusMessage),
                  Flexible(
                    child: ScanPreview(
                      scannedImage: _scannedImage,
                      isLoading: _isLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ScanActionButtons(
                    scannedImage: _scannedImage,
                    isExporting: _isExporting,
                    onPickImage: _pickAndCropImage,
                    onExportPdf: _exportPdf,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
