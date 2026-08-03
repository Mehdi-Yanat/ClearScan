import 'dart:io';
// dart:typed_data types are available via flutter/foundation.dart

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

// Parameters holder for compute since compute supports a single message arg.
class _ProcessParams {
  final Uint8List bytes;
  final int quality;
  _ProcessParams(this.bytes, this.quality);
}

// Runs in a background isolate.
Future<Uint8List> _processImageBytes(_ProcessParams params) async {
  final img.Image? rawImage = img.decodeImage(params.bytes);
  if (rawImage == null) {
    throw Exception('Could not decode scanned image.');
  }

  final img.Image filtered = img.grayscale(
    img.adjustColor(rawImage, contrast: 1.2, saturation: 0.0),
  );

  return Uint8List.fromList(img.encodeJpg(filtered, quality: params.quality));
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ClearScan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ScannerPage(),
    );
  }
}

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

    // Capture any BuildContext-dependent values before awaiting to avoid
    // 'use_build_context_synchronously' lint errors.
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
      } catch (e) {
        // If the crop plugin fails at runtime (native errors), fall back to
        // using the original picked image so the app doesn't crash.
        final File fallbackProcessed = await _processScannedImage(
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

      final File processedImage = await _processScannedImage(
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

  Widget _buildPreview() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_scannedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          _scannedImage!,
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

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _pickAndCropImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Scan with Camera'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _pickAndCropImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library),
          label: const Text('Choose from Gallery'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (_scannedImage != null) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(_isExporting ? 'Exporting PDF...' : 'Export as PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Scan an image', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          _statusMessage ??
              'Capture from camera or choose an image from gallery.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<File> _processScannedImage(File sourceFile) async {
    final Uint8List bytes = await sourceFile.readAsBytes();

    // Offload heavy image processing to a background isolate to avoid
    // blocking the UI thread (prevents freezes/crashes on large images).
    final Uint8List processedBytes = await compute(
      _processImageBytes,
      _ProcessParams(bytes, 92),
    );

    final Directory tempDir = Directory.systemTemp;
    final File outputFile = File(
      '${tempDir.path}/scanned_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await outputFile.writeAsBytes(processedBytes);
    return outputFile;
  }

  // (helpers are declared at top-level earlier in this file)

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
      final Uint8List imageBytes = await _scannedImage!.readAsBytes();
      final pw.Document document = pw.Document();
      final pw.MemoryImage pdfImage = pw.MemoryImage(imageBytes);
      final pdf.PdfPageFormat a4 = pdf.PdfPageFormat.a4;

      document.addPage(
        pw.Page(
          pageFormat: a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Container(
              width: a4.width,
              height: a4.height,
              color: pdf.PdfColors.white,
              child: pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              ),
            );
          },
        ),
      );

      // First try to save via platform MediaStore APIs on Android so the
      // exported PDF is visible in the system Downloads app. Fall back to
      // writing to external directories if the platform call fails.
      final Uint8List documentBytes = await document.save();
      if (Platform.isAndroid) {
        try {
          final String filename =
              'scanned_document_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final String? uri = await _platform.invokeMethod('saveToDownloads', {
            'filename': filename,
            'bytes': documentBytes,
          });
          if (uri != null) {
            setState(() {
              _statusMessage = 'PDF saved as $filename';
            });
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved PDF as $filename'),
                action: SnackBarAction(
                  label: 'Open',
                  onPressed: () async {
                    try {
                      await _platform.invokeMethod('openUri', {'uri': uri});
                    } catch (e) {
                      // ignore - best effort to open
                    }
                  },
                ),
              ),
            );
            return;
          }
        } catch (e) {
          // ignore and fall back to writing file directly
        }
      }

      // Prefer saving to the public Downloads directory on Android so the
      // exported PDF is visible to the user via file manager.
      Directory targetDir;
      if (Platform.isAndroid) {
        try {
          final List<Directory>? downloads = await path_provider
              .getExternalStorageDirectories(
                type: path_provider.StorageDirectory.downloads,
              );
          if (downloads != null && downloads.isNotEmpty) {
            targetDir = downloads.first;
          } else {
            final Directory fallback = Directory(
              '/storage/emulated/0/Download',
            );
            if (await fallback.exists()) {
              targetDir = fallback;
            } else {
              targetDir = await path_provider
                  .getApplicationDocumentsDirectory();
            }
          }
        } catch (e) {
          targetDir = await path_provider.getApplicationDocumentsDirectory();
        }
      } else {
        targetDir = await path_provider.getApplicationDocumentsDirectory();
      }

      final String filename =
          'scanned_document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File pdfFile = File('${targetDir.path}/$filename');
      await pdfFile.writeAsBytes(await document.save());

      final String savedPath = pdfFile.path;
      setState(() {
        _statusMessage = 'PDF saved as $filename';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved PDF as $filename'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              try {
                await _platform.invokeMethod('openUri', {'uri': savedPath});
              } catch (e) {
                // ignore - best effort to open
              }
            },
          ),
        ),
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
                          _buildInfoSection(context),
                          Expanded(child: _buildPreview()),
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
                          _buildActionButtons(),
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
                  _buildInfoSection(context),
                  Flexible(child: _buildPreview()),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
