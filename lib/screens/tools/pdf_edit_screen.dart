import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../services/pdf/pdf_editor.dart';
import '../../theme/app_theme.dart';

class PdfEditScreen extends StatefulWidget {
  const PdfEditScreen({required this.operation, super.key});

  final PdfEditOperation operation;

  @override
  State<PdfEditScreen> createState() => _PdfEditScreenState();
}

class _PdfEditScreenState extends State<PdfEditScreen> {
  static const _filesChannel = MethodChannel('com.opensource.clearscan/files');

  final _pageRangeController = TextEditingController();
  final _sourcePasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Uint8List? _inputBytes;
  String? _sourceName;
  List<File> _outputFiles = [];
  List<int> _pageOrder = [];
  int? _pageCount;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pageRangeController.dispose();
    _sourcePasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _title(AppLocalizations strings) => switch (widget.operation) {
    PdfEditOperation.split => strings.toolSplitPdf,
    PdfEditOperation.compress => strings.toolCompressPdf,
    PdfEditOperation.rotate => strings.toolRotatePdf,
    PdfEditOperation.deletePages => strings.toolDeletePages,
    PdfEditOperation.reorderPages => strings.toolReorderPages,
    PdfEditOperation.extractPages => strings.toolExtractPages,
    PdfEditOperation.addPassword => strings.toolAddPassword,
  };

  bool get _usesPageRange => switch (widget.operation) {
    PdfEditOperation.split ||
    PdfEditOperation.rotate ||
    PdfEditOperation.deletePages ||
    PdfEditOperation.extractPages => true,
    _ => false,
  };

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result == null) return;
    final path = result.path;
    if (path == null || path.isEmpty) {
      setState(() {
        _error = 'The selected PDF file could not be accessed.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _inputBytes = null;
      _pageCount = null;
      _outputFiles = [];
      _pageOrder = [];
      _sourceName = result.name;
    });
    try {
      _inputBytes = await File(path).readAsBytes();
      await _loadPdf();
    } catch (error) {
      if (mounted) {
        setState(() {
          _pageCount = null;
          _pageOrder = [];
          _error = AppLocalizations.of(context)!.pdfEditOpenFailed;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadPdf() async {
    final bytes = _inputBytes;
    if (bytes == null) return;
    try {
      final pageCount = getPdfPageCount(
        bytes,
        password: _sourcePasswordController.text,
      );
      if (!mounted) return;
      setState(() {
        _pageCount = pageCount;
        _pageOrder = List.generate(pageCount, (index) => index + 1);
        _pageRangeController.text =
            widget.operation == PdfEditOperation.deletePages
            ? ''
            : '1-$pageCount';
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _pageCount = null;
          _pageOrder = [];
          _error = AppLocalizations.of(context)!.pdfEditOpenFailed;
        });
      }
    }
  }

  Future<void> _runEdit() async {
    final strings = AppLocalizations.of(context)!;
    final bytes = _inputBytes;
    final pageCount = _pageCount;
    if (bytes == null || pageCount == null) return;
    if (widget.operation == PdfEditOperation.compress) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(strings.pdfEditCompressionWarningTitle),
          content: Text(strings.pdfEditCompressionNote),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.pdfEditCompressionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.pdfEditCompressionConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    if (widget.operation == PdfEditOperation.addPassword &&
        _newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = strings.pdfEditPasswordsDoNotMatch);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _outputFiles = [];
    });
    final savedFiles = <File>[];
    try {
      final pages = _usesPageRange
          ? parsePdfPageRanges(_pageRangeController.text, pageCount: pageCount)
          : const <int>[];
      final results = await editPdfBytes(
        inputBytes: bytes,
        operation: widget.operation,
        pages: pages,
        pageOrder: _pageOrder,
        sourcePassword: _sourcePasswordController.text,
        newPassword: _newPasswordController.text,
      );
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final outputDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}documents'
        '${Platform.pathSeparator}pdf_edits',
      );
      await outputDirectory.create(recursive: true);
      final stem = (_sourceName ?? 'document')
          .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final safeStem = stem.isEmpty ? 'document' : stem;
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      for (final result in results) {
        final filename = '${safeStem}_${result.suffix}_$timestamp.pdf';
        final file = File(
          '${outputDirectory.path}${Platform.pathSeparator}$filename',
        );
        await file.writeAsBytes(result.bytes, flush: true);
        savedFiles.add(file);
        if (Platform.isAndroid) {
          final uri = await _filesChannel.invokeMethod<String>(
            'saveToDownloads',
            {
              'filename': filename,
              'mimeType': 'application/pdf',
              'bytes': result.bytes,
            },
          );
          if (uri == null || uri.isEmpty) {
            throw StateError('Android did not return the saved PDF location.');
          }
        }
      }
      if (mounted) setState(() => _outputFiles = savedFiles);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is PdfCompressionNoReductionException
              ? strings.pdfEditCompressionNoReduction
              : error.toString();
          _outputFiles = savedFiles;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareFile(File file) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: file.uri.pathSegments.last,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final primary = AppColors.primary(context);
    final pageCount = _pageCount;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(_title(strings)),
        backgroundColor: AppColors.background(context),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              strings.pdfEditChoosePdf,
              style: TextStyle(color: AppColors.textMuted(context)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _pickPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(strings.pdfEditChoosePdf),
            ),
            if (_sourceName != null) ...[
              const SizedBox(height: 12),
              Text(
                _sourceName!,
                style: TextStyle(
                  color: AppColors.ink(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _sourcePasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: strings.pdfEditSourcePassword,
                helperText: strings.pdfEditSourcePasswordHelp,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_pageCount != null || _error != null) {
                  setState(() {
                    _pageCount = null;
                    _pageOrder = [];
                    _outputFiles = [];
                    _error = null;
                  });
                }
              },
              onSubmitted: (_) => _loadPdf(),
            ),
            if (_inputBytes != null && pageCount == null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _loadPdf,
                child: Text(strings.pdfEditLoadAgain),
              ),
            ],
            if (pageCount != null) ...[
              const SizedBox(height: 16),
              Text(
                strings.pdfEditPageCount(pageCount),
                style: TextStyle(color: AppColors.textMuted(context)),
              ),
            ],
            if (_usesPageRange && pageCount != null) ...[
              const SizedBox(height: 16),
              if (widget.operation == PdfEditOperation.split)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    strings.pdfEditSplitHint,
                    style: TextStyle(color: AppColors.textMuted(context)),
                  ),
                ),
              if (widget.operation == PdfEditOperation.rotate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    strings.pdfEditRotateHint,
                    style: TextStyle(color: AppColors.textMuted(context)),
                  ),
                ),
              TextField(
                controller: _pageRangeController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: strings.pdfEditPageRange,
                  hintText: strings.pdfEditPageRangeHint,
                  helperText: strings.pdfEditPageRangeHelp,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            if (widget.operation == PdfEditOperation.reorderPages &&
                pageCount != null) ...[
              const SizedBox(height: 12),
              Text(
                strings.pdfEditReorderHint,
                style: TextStyle(color: AppColors.textMuted(context)),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < _pageOrder.length; index++)
                Card(
                  key: ValueKey(_pageOrder[index]),
                  color: AppColors.surface(context),
                  child: ListTile(
                    leading: Icon(Icons.drag_handle, color: primary),
                    title: Text(strings.pdfEditPage(_pageOrder[index])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: strings.pdfEditMoveUp,
                          onPressed: index == 0
                              ? null
                              : () =>
                                    setState(() => _movePage(index, index - 1)),
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                        IconButton(
                          tooltip: strings.pdfEditMoveDown,
                          onPressed: index == _pageOrder.length - 1
                              ? null
                              : () =>
                                    setState(() => _movePage(index, index + 1)),
                          icon: const Icon(Icons.arrow_downward_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            if (widget.operation == PdfEditOperation.addPassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: strings.pdfEditNewPassword,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: strings.pdfEditConfirmPassword,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            if (widget.operation == PdfEditOperation.compress) ...[
              const SizedBox(height: 12),
              Text(
                strings.pdfEditCompressionNote,
                style: TextStyle(color: AppColors.textMuted(context)),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy || _inputBytes == null || pageCount == null
                  ? null
                  : _runEdit,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.pdfEditRun(_title(strings))),
            ),
            if (_outputFiles.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                strings.pdfEditDone,
                style: TextStyle(
                  color: AppColors.ink(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              for (final file in _outputFiles)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.picture_as_pdf, color: primary),
                  title: Text(file.uri.pathSegments.last),
                  trailing: IconButton(
                    tooltip: strings.share,
                    onPressed: () => _shareFile(file),
                    icon: const Icon(Icons.share_rounded),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _movePage(int oldIndex, int newIndex) {
    final page = _pageOrder.removeAt(oldIndex);
    _pageOrder.insert(newIndex, page);
  }
}
