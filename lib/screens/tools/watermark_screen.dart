import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../services/pdf_editor.dart';
import '../../theme/app_theme.dart';

class WatermarkScreen extends StatefulWidget {
  const WatermarkScreen({super.key});

  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends State<WatermarkScreen> {
  static const _filesChannel = MethodChannel('com.example.scanner/files');
  static const _previewHeight = 360.0;

  final _textController = TextEditingController();
  final Set<int> _pagePointerIds = {};
  Uint8List? _inputBytes;
  Uint8List? _pagePreview;
  Size? _pageSize;
  String? _sourceName;
  int? _pageCount;
  File? _outputFile;
  Offset _watermarkPosition = const Offset(0.1, 0.5);
  double _opacity = 0.2;
  bool _busy = false;
  bool _loadingPreview = false;
  String? _error;
  int _previewRequest = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<(Uint8List, Size)> _renderPage(Uint8List bytes) async {
    final document = await pdfx.PdfDocument.openData(bytes);
    try {
      final page = await document.getPage(1);
      try {
        final longestSide = page.width > page.height ? page.width : page.height;
        final scale = 1200 / longestSide;
        final image = await page.render(
          width: (page.width * scale).roundToDouble(),
          height: (page.height * scale).roundToDouble(),
          format: pdfx.PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        if (image == null || image.bytes.isEmpty) {
          throw StateError('Could not render the first PDF page.');
        }
        return (
          image.bytes,
          Size(page.width.toDouble(), page.height.toDouble()),
        );
      } finally {
        await page.close();
      }
    } finally {
      await document.close();
    }
  }

  Future<void> _loadPagePreview(Uint8List bytes) async {
    final request = ++_previewRequest;
    setState(() {
      _loadingPreview = true;
      _pagePreview = null;
      _pageSize = null;
      _error = null;
      _outputFile = null;
    });
    try {
      final (preview, size) = await _renderPage(bytes);
      if (!mounted || request != _previewRequest) return;
      setState(() {
        _pagePreview = preview;
        _pageSize = size;
      });
    } catch (error) {
      if (mounted && request == _previewRequest) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && request == _previewRequest) {
        setState(() => _loadingPreview = false);
      }
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (!mounted || result == null) return;
    final path = result.path;
    if (path == null || path.isEmpty) {
      setState(
        () => _error = AppLocalizations.of(context)!.watermarkPdfAccessFailed,
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _previewRequest++;
      _inputBytes = null;
      _pagePreview = null;
      _pageSize = null;
      _sourceName = result.name;
      _pageCount = null;
      _outputFile = null;
    });
    try {
      final bytes = await File(path).readAsBytes();
      final pageCount = getPdfPageCount(bytes);
      if (!mounted) return;
      setState(() {
        _inputBytes = bytes;
        _pageCount = pageCount;
        _watermarkPosition = const Offset(0.1, 0.5);
      });
      await _loadPagePreview(bytes);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context)!.pdfEditOpenFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyWatermark() async {
    final bytes = _inputBytes;
    final text = _textController.text.trim();
    if (bytes == null || text.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
      _outputFile = null;
    });
    try {
      final watermarkedBytes = addPdfWatermark(
        inputBytes: bytes,
        text: text,
        opacity: _opacity,
        position: _watermarkPosition,
      );
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final outputDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}documents'
        '${Platform.pathSeparator}watermarked_pdfs',
      );
      await outputDirectory.create(recursive: true);

      final stem = (_sourceName ?? 'document')
          .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final safeStem = stem.isEmpty ? 'document' : stem;
      final filename =
          '${safeStem}_watermarked_${DateTime.now().microsecondsSinceEpoch}.pdf';
      final file = File(
        '${outputDirectory.path}${Platform.pathSeparator}$filename',
      );
      await file.writeAsBytes(watermarkedBytes, flush: true);

      if (Platform.isAndroid) {
        final uri = await _filesChannel.invokeMethod<String>(
          'saveToDownloads',
          {
            'filename': filename,
            'mimeType': 'application/pdf',
            'bytes': watermarkedBytes,
          },
        );
        if (uri == null || uri.isEmpty) {
          throw StateError('Android did not return the saved PDF location.');
        }
      }
      if (mounted) setState(() => _outputFile = file);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
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

  void _moveWatermark(Offset delta, Size displaySize, Size pageSize) {
    final boundsWidth = pageSize.width * 0.8;
    final boundsHeight = pageSize.height < 64 ? pageSize.height : 64.0;
    final position = Offset(
      (_watermarkPosition.dx + delta.dx / displaySize.width)
          .clamp(0.0, (pageSize.width - boundsWidth) / pageSize.width)
          .toDouble(),
      (_watermarkPosition.dy + delta.dy / displaySize.height)
          .clamp(0.0, (pageSize.height - boundsHeight) / pageSize.height)
          .toDouble(),
    );
    setState(() {
      _watermarkPosition = position;
      _outputFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final primary = AppColors.primary(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(strings.toolWatermark),
        backgroundColor: AppColors.background(context),
      ),
      body: SafeArea(
        child: ListView(
          physics: _pagePointerIds.isEmpty
              ? null
              : const NeverScrollableScrollPhysics(),
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
            if (_pageCount != null) ...[
              const SizedBox(height: 12),
              Text(
                strings.pdfEditPageCount(_pageCount!),
                style: TextStyle(color: AppColors.textMuted(context)),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              strings.watermarkPositionHint,
              style: TextStyle(color: AppColors.textMuted(context)),
            ),
            const SizedBox(height: 8),
            SizedBox(height: _previewHeight, child: _buildPagePreview(strings)),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: strings.watermarkText,
                hintText: strings.watermarkTextHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _outputFile = null),
            ),
            const SizedBox(height: 8),
            Text(
              strings.watermarkOpacity,
              style: TextStyle(
                color: AppColors.ink(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.opacity_rounded),
                Expanded(
                  child: Slider(
                    value: _opacity,
                    min: 0.1,
                    max: 0.6,
                    divisions: 10,
                    label: '${(_opacity * 100).round()}%',
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                            _opacity = value;
                            _outputFile = null;
                          }),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('${(_opacity * 100).round()}%'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                strings.watermarkAllPagesHint,
                style: TextStyle(color: AppColors.textMuted(context)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed:
                  _busy ||
                      _loadingPreview ||
                      _pagePreview == null ||
                      _inputBytes == null ||
                      _textController.text.trim().isEmpty
                  ? null
                  : _applyWatermark,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.watermarkApply),
            ),
            if (_outputFile case final file?) ...[
              const SizedBox(height: 24),
              Text(
                strings.pdfEditDone,
                style: TextStyle(
                  color: AppColors.ink(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.picture_as_pdf_rounded, color: primary),
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

  Widget _buildPagePreview(AppLocalizations strings) {
    final preview = _pagePreview;
    final pageSize = _pageSize;
    if (_loadingPreview) {
      return const Center(child: CircularProgressIndicator());
    }
    if (preview == null || pageSize == null) {
      return Center(
        child: Text(
          strings.watermarkPreviewUnavailable,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = applyBoxFit(
          BoxFit.contain,
          pageSize,
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        final displaySize = fitted.destination;
        final pageCanvasSize = Size(
          displaySize.width - 2,
          displaySize.height - 2,
        );
        final watermarkWidth = pageCanvasSize.width * 0.8;
        final watermarkHeight = pageSize.height < 64
            ? pageCanvasSize.height
            : pageCanvasSize.height * (64 / pageSize.height);
        final left =
            _watermarkPosition.dx * (pageCanvasSize.width - watermarkWidth);
        final top =
            _watermarkPosition.dy * (pageCanvasSize.height - watermarkHeight);
        final fontSize = 40 * (pageCanvasSize.width / pageSize.width);

        return Center(
          child: Listener(
            onPointerDown: (event) {
              setState(() => _pagePointerIds.add(event.pointer));
            },
            onPointerUp: (event) {
              setState(() => _pagePointerIds.remove(event.pointer));
            },
            onPointerCancel: (event) {
              setState(() => _pagePointerIds.remove(event.pointer));
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _busy
                  ? null
                  : (details) =>
                        _moveWatermark(details.delta, pageCanvasSize, pageSize),
              child: Container(
                width: displaySize.width,
                height: displaySize.height,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(preview, fit: BoxFit.fill),
                    ),
                    Positioned(
                      left: left,
                      top: top,
                      width: watermarkWidth,
                      height: watermarkHeight,
                      child: IgnorePointer(
                        child: Center(
                          child: Opacity(
                            opacity: _opacity,
                            child: Text(
                              _textController.text.trim().isEmpty
                                  ? strings.watermarkTextHint
                                  : _textController.text.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF808080),
                                fontSize: fontSize.clamp(8.0, 40.0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
