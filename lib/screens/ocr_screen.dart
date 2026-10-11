import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  static const _ocrLanguages = 'eng+deu+ara';

  File? _imageFile;
  String? _recognizedText;
  String? _error;
  bool _busy = false;

  Future<void> _pickImageAndRunOcr() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _recognizedText = null;
    });

    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (!mounted || image == null) return;

      final file = File(image.path);
      setState(() => _imageFile = file);
      final text = await FlutterTesseractOcr.extractText(
        image.path,
        language: _ocrLanguages,
        args: const {'preserve_interword_spaces': '1', 'psm': '3'},
      );
      if (!mounted) return;
      if (text.replaceAll(RegExp(r'[\s\u0000-\u001f]'), '').isEmpty) {
        setState(() => _error = AppLocalizations.of(context)!.ocrNoText);
        return;
      }
      setState(() => _recognizedText = text.trim());
    } on Exception catch (error) {
      if (mounted) {
        setState(
          () =>
              _error = AppLocalizations.of(context)!
                  .ocrFailed(error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyText() async {
    final text = _recognizedText;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      showAppSnackBar(context, AppLocalizations.of(context)!.ocrCopied);
    }
  }

  Future<void> _shareText() async {
    final text = _recognizedText;
    if (text == null || text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: AppLocalizations.of(context)!.toolOcr),
      );
    } on Exception catch (error) {
      if (mounted) {
        setState(
          () =>
              _error = AppLocalizations.of(context)!
                  .ocrFailed(error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final recognizedText = _recognizedText;
    final imageFile = _imageFile;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(strings.toolOcr),
        backgroundColor: AppColors.background(context),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 56,
              color: AppColors.primary(context),
            ),
            const SizedBox(height: 16),
            Text(
              strings.ocrHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted(context)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _pickImageAndRunOcr,
              icon: const Icon(Icons.image_search_rounded),
              label: Text(strings.ocrSelectImage),
            ),
            if (imageFile != null) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  imageFile,
                  height: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => SizedBox(
                    height: 120,
                    child: Center(child: Text(strings.ocrImagePreviewFailed)),
                  ),
                ),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Text(
                strings.ocrProcessing,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted(context)),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (recognizedText != null) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.ocrResult,
                      style: TextStyle(
                        color: AppColors.ink(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.ocrCopy,
                    onPressed: _busy ? null : _copyText,
                    icon: const Icon(Icons.copy_rounded),
                  ),
                  IconButton(
                    tooltip: strings.share,
                    onPressed: _busy ? null : _shareText,
                    icon: const Icon(Icons.share_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: SelectableText(
                  recognizedText,
                  style: TextStyle(color: AppColors.ink(context), height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
