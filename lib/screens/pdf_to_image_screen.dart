import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/pdf_to_image_converter.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';

class PdfToImageScreen extends StatefulWidget {
  const PdfToImageScreen({super.key});

  @override
  State<PdfToImageScreen> createState() => _PdfToImageScreenState();
}

class _PdfToImageScreenState extends State<PdfToImageScreen> {
  bool _busy = false;
  int _completedPages = 0;
  int _totalPages = 0;
  String? _error;
  String? _sourceName;
  List<File> _convertedFiles = const [];

  Future<void> _pickAndConvert() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _completedPages = 0;
      _totalPages = 0;
      _error = null;
      _sourceName = null;
      _convertedFiles = const [];
    });

    try {
      final selectedFile = await FilePicker.pickFile(
        dialogTitle: AppLocalizations.of(context)!.pdfToImageSelectPdf,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (selectedFile == null) return;

      final path = selectedFile.path;
      if (path == null || path.isEmpty) {
        throw const FormatException(
          'The selected PDF file could not be accessed.',
        );
      }

      final files = await convertPdfToImages(
        pdfFile: File(path),
        sourceName: selectedFile.name,
        onProgress: (completed, total) {
          if (!mounted) return;
          setState(() {
            _completedPages = completed;
            _totalPages = total;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _sourceName = selectedFile.name;
        _convertedFiles = files;
      });
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImages() async {
    if (_busy || _convertedFiles.isEmpty) return;
    setState(() => _busy = true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: _convertedFiles.map((file) => XFile(file.path)).toList(),
          subject: _sourceName,
        ),
      );
    } on Exception catch (error) {
      if (mounted) {
        final strings = AppLocalizations.of(context)!;
        showAppSnackBar(
          context,
          strings.pdfToImageShareFailed(error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(strings.pdfToImageTitle),
        backgroundColor: AppColors.background(context),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.image_rounded,
              size: 56,
              color: AppColors.primary(context),
            ),
            const SizedBox(height: 16),
            Text(
              strings.pdfToImageHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textMuted(context),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _pickAndConvert,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(strings.pdfToImageSelectPdf),
            ),
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              if (_totalPages > 0) ...[
                const SizedBox(height: 12),
                Text(
                  strings.pdfToImageProgress(_completedPages, _totalPages),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  strings.pdfToImageConverting,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 24),
              Text(
                strings.pdfToImageConversionFailed(_error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_convertedFiles.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                strings.pdfToImageConvertedPages(_convertedFiles.length),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink(context),
                ),
              ),
              const SizedBox(height: 8),
              for (final file in _convertedFiles)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.image_outlined,
                    color: AppColors.primary(context),
                  ),
                  title: Text(file.uri.pathSegments.last),
                  dense: true,
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _shareImages,
                icon: const Icon(Icons.share_rounded),
                label: Text(strings.pdfToImageShare),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
