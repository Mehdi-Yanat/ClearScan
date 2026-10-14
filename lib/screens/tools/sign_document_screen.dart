import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../services/pdf/pdf_editor.dart';
import '../../theme/app_theme.dart';

class SignDocumentScreen extends StatefulWidget {
  const SignDocumentScreen({super.key});

  @override
  State<SignDocumentScreen> createState() => _SignDocumentScreenState();
}

class _SignDocumentScreenState extends State<SignDocumentScreen> {
  static const _filesChannel = MethodChannel('com.opensource.clearscan/files');
  static const _signatureSize = Size(1200, 360);
  static const _previewHeight = 360.0;

  final List<List<Offset>> _strokes = [];
  final Set<int> _pagePointerIds = {};
  Uint8List? _inputBytes;
  Uint8List? _pagePreview;
  Size? _pageSize;
  String? _sourceName;
  File? _outputFile;
  int? _pageCount;
  int _pageNumber = 1;
  Offset _signaturePosition = const Offset(0.1, 0.75);
  bool _whiteSignature = false;
  bool _busy = false;
  bool _loadingPreview = false;
  String? _error;
  int _previewRequest = 0;

  bool get _hasSignature => _strokes.any((stroke) => stroke.isNotEmpty);

  Color get _signatureColor =>
      _whiteSignature ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

  Future<(Uint8List, Size)> _renderPage(Uint8List bytes, int pageNumber) async {
    final document = await pdfx.PdfDocument.openData(bytes);
    try {
      final page = await document.getPage(pageNumber);
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
          throw StateError('Could not render PDF page $pageNumber.');
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

  Future<void> _loadPagePreview(Uint8List bytes, int pageNumber) async {
    final request = ++_previewRequest;
    setState(() {
      _loadingPreview = true;
      _pagePreview = null;
      _pageSize = null;
      _error = null;
      _outputFile = null;
    });
    try {
      final (preview, size) = await _renderPage(bytes, pageNumber);
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
      setState(() => _error = 'The selected PDF file could not be accessed.');
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
      _pageNumber = 1;
      _outputFile = null;
    });
    try {
      final bytes = await File(path).readAsBytes();
      final pageCount = getPdfPageCount(bytes);
      if (!mounted) return;
      setState(() {
        _inputBytes = bytes;
        _pageCount = pageCount;
      });
      await _loadPagePreview(bytes, 1);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.pdfEditOpenFailed;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _createSignaturePng() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, _signatureSize.width, _signatureSize.height),
    );
    _SignaturePainter(_strokes, _signatureColor).paint(canvas, _signatureSize);
    final image = await recorder.endRecording().toImage(
      _signatureSize.width.toInt(),
      _signatureSize.height.toInt(),
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('Could not encode the signature image.');
      }
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _signPdf() async {
    final bytes = _inputBytes;
    if (bytes == null || !_hasSignature) return;

    setState(() {
      _busy = true;
      _error = null;
      _outputFile = null;
    });
    try {
      final signatureBytes = await _createSignaturePng();
      final signedBytes = signPdfBytes(
        inputBytes: bytes,
        signaturePngBytes: signatureBytes,
        pageNumber: _pageNumber,
        signaturePosition: _signaturePosition,
      );
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final outputDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}documents'
        '${Platform.pathSeparator}signed_pdfs',
      );
      await outputDirectory.create(recursive: true);

      final stem = (_sourceName ?? 'document')
          .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final safeStem = stem.isEmpty ? 'document' : stem;
      final filename =
          '${safeStem}_signed_${DateTime.now().microsecondsSinceEpoch}.pdf';
      final file = File(
        '${outputDirectory.path}${Platform.pathSeparator}$filename',
      );
      await file.writeAsBytes(signedBytes, flush: true);

      if (Platform.isAndroid) {
        final uri = await _filesChannel.invokeMethod<String>(
          'saveToDownloads',
          {
            'filename': filename,
            'mimeType': 'application/pdf',
            'bytes': signedBytes,
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

  void _addPoint(Offset localPosition, Size size) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(
      Offset(
        (localPosition.dx / size.width).clamp(0.0, 1.0).toDouble(),
        (localPosition.dy / size.height).clamp(0.0, 1.0).toDouble(),
      ),
    );
    setState(() => _outputFile = null);
  }

  void _moveSignature(Offset delta, Size pageDisplaySize, Size pageSize) {
    var width = pageSize.width < 180 ? pageSize.width : 180.0;
    final maxWidthForHeight = pageSize.height * 3.6;
    if (width > maxWidthForHeight) width = maxWidthForHeight;
    final height = width / 3.6;
    final position = Offset(
      (_signaturePosition.dx + delta.dx / pageDisplaySize.width)
          .clamp(0.0, (pageSize.width - width) / pageSize.width)
          .toDouble(),
      (_signaturePosition.dy + delta.dy / pageDisplaySize.height)
          .clamp(0.0, (pageSize.height - height) / pageSize.height)
          .toDouble(),
    );
    setState(() {
      _signaturePosition = position;
      _outputFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final pageCount = _pageCount;
    final primary = AppColors.primary(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(strings.toolSign),
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
            if (pageCount != null) ...[
              const SizedBox(height: 12),
              Text(
                strings.pdfEditPageCount(pageCount),
                style: TextStyle(color: AppColors.textMuted(context)),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _pageNumber,
                decoration: InputDecoration(
                  labelText: strings.pdfEditPage(_pageNumber),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (var page = 1; page <= pageCount; page++)
                    DropdownMenuItem(
                      value: page,
                      child: Text(strings.pdfEditPage(page)),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (page) {
                        if (page != null) {
                          setState(() {
                            _pageNumber = page;
                            _pagePreview = null;
                            _pageSize = null;
                            _outputFile = null;
                          });
                          final bytes = _inputBytes;
                          if (bytes != null) _loadPagePreview(bytes, page);
                        }
                      },
              ),
            ],
            const SizedBox(height: 24),
            Text(
              strings.toolSignDesc,
              style: TextStyle(
                color: AppColors.ink(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.signaturePlacementHint,
              style: TextStyle(color: AppColors.textMuted(context)),
            ),
            const SizedBox(height: 12),
            SizedBox(height: _previewHeight, child: _buildPagePreview(strings)),
            const SizedBox(height: 20),
            Text(
              strings.signatureColor,
              style: TextStyle(
                color: AppColors.ink(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(strings.signatureBlack),
                ),
                ButtonSegment(value: true, label: Text(strings.signatureWhite)),
              ],
              selected: {_whiteSignature},
              showSelectedIcon: false,
              onSelectionChanged: _busy
                  ? null
                  : (selection) {
                      setState(() {
                        _whiteSignature = selection.first;
                        _outputFile = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            _buildSignaturePad(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _busy || !_hasSignature
                    ? null
                    : () => setState(() {
                        _strokes.clear();
                        _outputFile = null;
                      }),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(strings.signatureClear),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  _busy ||
                      _loadingPreview ||
                      _pagePreview == null ||
                      _inputBytes == null ||
                      !_hasSignature
                  ? null
                  : _signPdf,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.toolSign),
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
          strings.signaturePreviewUnavailable,
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
        var signatureWidth = pageSize.width < 180
            ? pageCanvasSize.width
            : pageCanvasSize.width * (180 / pageSize.width);
        final maxWidthForHeight = pageCanvasSize.height * 3.6;
        if (signatureWidth > maxWidthForHeight) {
          signatureWidth = maxWidthForHeight;
        }
        final signatureHeight = signatureWidth / 3.6;
        final left =
            _signaturePosition.dx * (pageCanvasSize.width - signatureWidth);
        final top =
            _signaturePosition.dy * (pageCanvasSize.height - signatureHeight);

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
                        _moveSignature(details.delta, pageCanvasSize, pageSize),
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
                      width: signatureWidth,
                      height: signatureHeight,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _whiteSignature
                                ? const Color(0x55303030)
                                : const Color(0x22FFFFFF),
                            border: Border.all(
                              color: AppColors.primary(context),
                              width: 1,
                            ),
                          ),
                          child: CustomPaint(
                            painter: _SignaturePainter(
                              _strokes,
                              _signatureColor,
                            ),
                            child: const SizedBox.expand(),
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

  Widget _buildSignaturePad() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: _whiteSignature
            ? const Color(0xFF303030)
            : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              setState(() {
                _strokes.add([]);
                _outputFile = null;
              });
              _addPoint(details.localPosition, size);
            },
            onPanUpdate: (details) => _addPoint(details.localPosition, size),
            child: CustomPaint(
              painter: _SignaturePainter(_strokes, _signatureColor),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes, this.color);

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.height / 60;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke.first.dx * size.width, stroke.first.dy * size.height),
          strokeWidth / 2,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()
        ..moveTo(stroke.first.dx * size.width, stroke.first.dy * size.height);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
