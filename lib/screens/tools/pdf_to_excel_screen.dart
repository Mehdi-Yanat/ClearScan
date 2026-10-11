import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../services/pdf_to_excel_converter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';

class PdfToExcelScreen extends StatefulWidget {
  const PdfToExcelScreen({super.key});

  @override
  State<PdfToExcelScreen> createState() => _PdfToExcelScreenState();
}

class _PdfToExcelScreenState extends State<PdfToExcelScreen> {
  bool _busy = false;
  int _completedPages = 0;
  int _totalPages = 0;
  String? _error;
  File? _convertedFile;

  Future<void> _pickAndConvert() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _completedPages = 0;
      _totalPages = 0;
      _error = null;
      _convertedFile = null;
    });

    try {
      final strings = AppLocalizations.of(context)!;
      final selectedFile = await FilePicker.pickFile(
        dialogTitle: strings.pdfToExcelSelectPdf,
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

      final outputFile = await convertPdfToExcel(
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
      setState(() => _convertedFile = outputFile);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareWorkbook() async {
    final file = _convertedFile;
    if (_busy || file == null) return;
    setState(() => _busy = true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: file.uri.pathSegments.last,
        ),
      );
    } on Exception catch (error) {
      if (mounted) {
        final strings = AppLocalizations.of(context)!;
        showAppSnackBar(
          context,
          strings.pdfToExcelShareFailed(error.toString()),
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
        title: Text(strings.pdfToExcelTitle),
        backgroundColor: AppColors.background(context),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.table_chart_rounded,
              size: 56,
              color: AppColors.primary(context),
            ),
            const SizedBox(height: 16),
            Text(
              strings.pdfToExcelHint,
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
              label: Text(strings.pdfToExcelSelectPdf),
            ),
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              if (_totalPages > 0) ...[
                const SizedBox(height: 12),
                Text(
                  strings.pdfToExcelProgress(_completedPages, _totalPages),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  strings.pdfToExcelConverting,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 24),
              Text(
                strings.pdfToExcelConversionFailed(_error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_convertedFile case final file?) ...[
              const SizedBox(height: 28),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.table_chart_outlined,
                  color: AppColors.primary(context),
                ),
                title: Text(file.uri.pathSegments.last),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _shareWorkbook,
                icon: const Icon(Icons.share_rounded),
                label: Text(strings.pdfToExcelShare),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
