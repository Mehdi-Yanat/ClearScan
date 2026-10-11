import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr/qr.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  static const _imageSize = 1024;
  static const _imageSizeDouble = 1024.0;

  final _textController = TextEditingController();
  bool _busy = false;
  String? _error;

  QrImage? get _qrImage {
    final data = _textController.text.trim();
    if (data.isEmpty) return null;
    try {
      return QrImage(
        QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
      );
    } on Exception {
      return null;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<Uint8List> _renderPng(QrImage qrImage) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, _imageSizeDouble, _imageSizeDouble),
    );
    _QrPainter(qrImage).paint(canvas, const Size.square(_imageSizeDouble));
    final image = await recorder.endRecording().toImage(_imageSize, _imageSize);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode the QR code image.');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _shareQrCode() async {
    final qrImage = _qrImage;
    if (qrImage == null || _busy) return;
    final subject = AppLocalizations.of(context)!.toolQrGenerator;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await _renderPng(qrImage);
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final outputDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}qr_codes',
      );
      await outputDirectory.create(recursive: true);
      final file = File(
        '${outputDirectory.path}${Platform.pathSeparator}'
        'qr_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: subject),
      );
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final qrImage = _qrImage;
    final hasInput = _textController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(strings.toolQrGenerator),
        backgroundColor: AppColors.background(context),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.qr_code_rounded,
              size: 56,
              color: AppColors.primary(context),
            ),
            const SizedBox(height: 16),
            Text(
              strings.qrGeneratorHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted(context)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              maxLength: 2000,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: strings.qrGeneratorContent,
                hintText: strings.qrGeneratorContentHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (hasInput && qrImage == null) ...[
              const SizedBox(height: 8),
              Text(
                strings.qrGeneratorTooLong,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (qrImage != null) ...[
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 280,
                  height: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: CustomPaint(painter: _QrPainter(qrImage)),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _shareQrCode,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(strings.qrGeneratorShare),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter(this.qrImage);

  final QrImage qrImage;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final moduleSize = size.width / (qrImage.moduleCount + 8);
    for (var row = 0; row < qrImage.moduleCount; row++) {
      for (var column = 0; column < qrImage.moduleCount; column++) {
        if (qrImage.isDark(row, column)) {
          canvas.drawRect(
            Rect.fromLTWH(
              (column + 4) * moduleSize,
              (row + 4) * moduleSize,
              moduleSize,
              moduleSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.qrImage != qrImage;
}
