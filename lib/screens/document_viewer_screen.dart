import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

import '../services/recent_documents.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/share_sheet.dart';

class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key, required this.document});

  final RecentDocument document;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  static const _filesChannel = MethodChannel('com.example.scanner/files');
  Uint8List? _pdfBytes;
  Object? _pdfLoadError;
  bool _loadingPdf = false;
  bool _sharing = false;

  bool get _isPdf => widget.document.type == 'PDF';

  Future<void> _shareDocument() async {
    if (_sharing) return;
    final action = await showShareSheet(
      context,
      title: widget.document.name,
      shareLabel: 'Share document',
      exportLabel: 'Save to device',
      fileType: widget.document.type,
      fileSizeBytes: widget.document.sizeBytes,
      previewImagePath: widget.document.type == 'PDF'
          ? null
          : widget.document.path,
      previewFilePath: widget.document.path,
      loadPreviewPdfBytes: widget.document.path.startsWith('content://')
          ? () => readRecentDocumentBytes(widget.document)
          : null,
    );
    if (!mounted || action == null) return;
    setState(() => _sharing = true);
    try {
      if (action == ShareSheetAction.export) {
        await saveRecentDocumentToDevice(widget.document);
        if (mounted) showAppSnackBar(context, 'Saved to device');
      } else if (widget.document.path.startsWith('content://')) {
        await shareRecentDocument(widget.document);
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(widget.document.path)],
            subject: widget.document.name,
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          action == ShareSheetAction.export
              ? 'Could not save to device: $error'
              : 'Could not share document: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isPdf && widget.document.path.startsWith('content://')) {
      _loadPdfBytes();
    }
  }

  Future<void> _loadPdfBytes() async {
    setState(() {
      _loadingPdf = true;
      _pdfLoadError = null;
    });
    try {
      final bytes = await _filesChannel.invokeMethod<Uint8List>(
        'readDocumentBytes',
        {'uri': widget.document.path},
      );
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException(
          'The PDF document is empty or could not be read.',
        );
      }
      if (mounted) setState(() => _pdfBytes = bytes);
    } on PlatformException catch (error) {
      if (mounted) setState(() => _pdfLoadError = error);
    } on Exception catch (error) {
      if (mounted) setState(() => _pdfLoadError = error);
    } finally {
      if (mounted) setState(() => _loadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final imagePath = document.path;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _sharing ? null : _shareDocument,
            tooltip: 'Share document',
            icon: _sharing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: _isPdf
          ? _buildPdfViewer()
          : InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Center(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(error.toString(), textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPdfViewer() {
    if (_loadingPdf) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pdfLoadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                'Could not load this PDF: $_pdfLoadError',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadPdfBytes,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    return PDFView(
      filePath: widget.document.path.startsWith('content://')
          ? null
          : widget.document.path,
      pdfData: widget.document.path.startsWith('content://') ? _pdfBytes : null,
      fitPolicy: FitPolicy.BOTH,
      onError: (error) {
        if (mounted) setState(() => _pdfLoadError = error);
      },
    );
  }
}
