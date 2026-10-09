import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart' as loc;
import '../services/recent_documents.dart';

class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key, required this.document});

  final RecentDocument document;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  static const _filesChannel = MethodChannel('com.example.scanner/files');
  bool _opening = false;

  bool get _isPdf => widget.document.type == 'PDF';

  Future<void> _openPdf() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final opened = await _filesChannel.invokeMethod<bool>('openUri', {
        'uri': widget.document.path,
      });
      if (opened != true) {
        throw PlatformException(
          code: 'open_failed',
          message: 'No PDF viewer could open this document.',
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error.message ?? 'Could not open this PDF (${error.code}).',
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
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
      ),
      body: _isPdf
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(document.name, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _opening ? null : _openPdf,
                      icon: _opening
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.open_in_new_rounded),
                      label: Text(loc.AppLocalizations.of(context)!.openPdf),
                    ),
                  ],
                ),
              ),
            )
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
}
