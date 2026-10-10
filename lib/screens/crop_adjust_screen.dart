import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../l10n/app_localizations.dart';
import '../services/document_quad_detector.dart';
import '../theme/app_theme.dart';

/// What the user chose when leaving the crop screen.
enum CropAction { next, addPage, retake }

class CropResult {
  const CropResult({required this.action, this.path});

  final CropAction action;

  /// Path of the cropped JPEG. Null when [action] is [CropAction.retake].
  final String? path;
}

/// Adjust-edges screen: drag 4 corners / 4 edge handles, rotate, auto crop,
/// then pop with a [CropResult].
///
///   final result = await Navigator.of(context).push(
///     `MaterialPageRoute<CropResult>(builder: (_) => CropAdjustScreen(imagePath: file.path))`,
///   );
class CropAdjustScreen extends StatefulWidget {
  const CropAdjustScreen({
    super.key,
    required this.imagePath,
    this.pageNumber = 1,
    this.totalPages = 1,
  });

  final String imagePath;
  final int pageNumber;
  final int totalPages;

  @override
  State<CropAdjustScreen> createState() => _CropAdjustScreenState();
}

class _CropAdjustScreenState extends State<CropAdjustScreen> {
  Uint8List? _bytes; // JPEG with EXIF orientation already baked in
  Size _imageSize = Size.zero;
  String? _error;
  bool _working = false;

  /// Quad in normalized image coordinates (0..1): TL, TR, BR, BL.
  List<Offset> _quad = _defaultQuad();

  static List<Offset> _defaultQuad() => const [
    Offset(0.08, 0.08),
    Offset(0.92, 0.08),
    Offset(0.92, 0.92),
    Offset(0.08, 0.92),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await File(widget.imagePath).readAsBytes();
      final bytes = await compute(_bakeOrientation, raw);
      await _setBytes(bytes);
      await _autoCrop(showFailure: false);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context)!.cropAdjustErrorOpenImage,
        );
      }
    }
  }

  Future<void> _setBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _imageSize = size;
    });
  }

  // ── actions ──

  Future<void> _rotate() async {
    final bytes = _bytes;
    if (bytes == null || _working) return;
    setState(() => _working = true);
    try {
      final rotated = await compute(_rotate90, bytes);
      // 90° clockwise: (x, y) -> (1 - y, x)
      _quad = [for (final p in _quad) Offset(1 - p.dy, p.dx)];
      await _setBytes(rotated);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _autoCrop({bool showFailure = true}) async {
    final bytes = _bytes;
    if (bytes == null || _working) return;
    setState(() => _working = true);
    try {
      final detected = await DocumentQuadDetector.detect(bytes);
      if (!mounted) return;
      if (detected == null) {
        if (showFailure) _showAutoCropMessage();
        return;
      }
      HapticFeedback.selectionClick();
      setState(() => _quad = detected);
    } on Exception {
      if (mounted) _showAutoCropMessage();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showAutoCropMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.cropAdjustErrorDetectEdges,
          ),
        ),
      );
  }

  Future<void> _finish(CropAction action) async {
    final bytes = _bytes;
    if (bytes == null || _working) return;
    setState(() => _working = true);
    try {
      final ordered = _orderedQuad();
      final cropped = await compute(
        _cropPerspective,
        _CropJob(
          bytes: bytes,
          points: [
            for (final p in ordered) [p.dx, p.dy],
          ],
        ),
      );
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/crop_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(cropped, flush: true);
      if (!mounted) return;
      Navigator.of(context).pop(CropResult(action: action, path: file.path));
    } catch (_) {
      if (mounted) {
        setState(() => _working = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.cropAdjustErrorCropImage,
              ),
            ),
          );
      }
    }
  }

  void _retake() =>
      Navigator.of(context).pop(const CropResult(action: CropAction.retake));

  /// Returns TL, TR, BR, BL regardless of how the points were dragged/rotated.
  List<Offset> _orderedQuad() {
    final pts = [..._quad]..sort((a, b) => a.dy.compareTo(b.dy));
    final top = [pts[0], pts[1]]..sort((a, b) => a.dx.compareTo(b.dx));
    final bottom = [pts[2], pts[3]]..sort((a, b) => a.dx.compareTo(b.dx));
    return [top[0], top[1], bottom[1], bottom[0]];
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    final accentColor = AppColors.primary(context);
    final backgroundColor = AppColors.background(context);
    final surfaceColor = AppColors.surface(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: surfaceColor,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                enabled: _bytes != null && !_working,
                onBack: () => Navigator.of(context).pop(),
                onNext: () => _finish(CropAction.next),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildEditor(accentColor: accentColor),
                          ),
                        ),
                      ),
                      if (_working)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: surfaceColor.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _PageBadge(page: widget.pageNumber, total: widget.totalPages),
              const SizedBox(height: 12),
              _BottomActions(
                enabled: _bytes != null && !_working,
                onRetake: _retake,
                onRotate: _rotate,
                onAutoCrop: () => _autoCrop(),
                onAddPage: () => _finish(CropAction.addPage),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor({required Color accentColor}) {
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(color: AppColors.textMuted(context), fontSize: 14),
        ),
      );
    }
    final bytes = _bytes;
    if (bytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, box) {
        const pad = 22.0; // room so handles at the image edge stay reachable
        final avail = Size(box.maxWidth - pad * 2, box.maxHeight - pad * 2);
        final scale = math.min(
          avail.width / _imageSize.width,
          avail.height / _imageSize.height,
        );
        final imgSize = Size(
          _imageSize.width * scale,
          _imageSize.height * scale,
        );
        final origin = Offset(
          (box.maxWidth - imgSize.width) / 2,
          (box.maxHeight - imgSize.height) / 2,
        );
        final imgRect = origin & imgSize;

        Offset toPx(Offset n) => Offset(
          imgRect.left + n.dx * imgRect.width,
          imgRect.top + n.dy * imgRect.height,
        );

        void moveBy(List<int> indices, Offset deltaPx) {
          final dn = Offset(
            deltaPx.dx / imgRect.width,
            deltaPx.dy / imgRect.height,
          );
          var dx = dn.dx;
          var dy = dn.dy;
          for (final i in indices) {
            dx = dx.clamp(-_quad[i].dx, 1 - _quad[i].dx);
            dy = dy.clamp(-_quad[i].dy, 1 - _quad[i].dy);
          }
          setState(() {
            for (final i in indices) {
              _quad[i] = Offset(_quad[i].dx + dx, _quad[i].dy + dy);
            }
          });
        }

        final px = [for (final p in _quad) toPx(p)];

        Widget handle(
          Offset center,
          List<int> indices, {
          required bool corner,
        }) {
          final size = corner ? 44.0 : 40.0;
          return Positioned(
            left: center.dx - size / 2,
            top: center.dy - size / 2,
            width: size,
            height: size,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => moveBy(indices, d.delta),
              child: Center(
                child: corner ? const _CornerDot() : const _EdgeDot(),
              ),
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fromRect(
              rect: imgRect,
              child: Image.memory(
                bytes,
                fit: BoxFit.fill,
                gaplessPlayback: true,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _QuadPainter(points: px, color: accentColor),
                ),
              ),
            ),
            // edges (drawn first so corners win overlaps)
            for (final e in const [
              [0, 1],
              [1, 2],
              [2, 3],
              [3, 0],
            ])
              handle((px[e[0]] + px[e[1]]) / 2, e, corner: false),
            for (var i = 0; i < 4; i++) handle(px[i], [i], corner: true),
          ],
        );
      },
    );
  }
}

// ───────────────────────────── UI pieces ─────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.enabled,
    required this.onBack,
    required this.onNext,
  });

  final bool enabled;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.ink(context);
    final accent = AppColors.primary(context);
    final disabledColor = AppColors.textHint(context);
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded, color: ink),
            tooltip: AppLocalizations.of(context)!.cropAdjustBack,
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.cropAdjustTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
          TextButton(
            onPressed: enabled ? onNext : null,
            child: Text(
              AppLocalizations.of(context)!.cropAdjustNext,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: enabled ? accent : disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageBadge extends StatelessWidget {
  const _PageBadge({required this.page, required this.total});

  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surface(context);
    final ink = AppColors.ink(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        '${AppLocalizations.of(context)!.cropAdjustPage} $page / $total',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.enabled,
    required this.onRetake,
    required this.onRotate,
    required this.onAutoCrop,
    required this.onAddPage,
  });

  final bool enabled;
  final VoidCallback onRetake;
  final VoidCallback onRotate;
  final VoidCallback onAutoCrop;
  final VoidCallback onAddPage;

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surface(context);
    final ink = AppColors.ink(context);
    final muted = AppColors.textMuted(context);
    final items = [
      (
        Icons.photo_camera_outlined,
        AppLocalizations.of(context)!.cropAdjustRetake,
        onRetake,
      ),
      (
        Icons.rotate_right_rounded,
        AppLocalizations.of(context)!.cropAdjustRotate,
        onRotate,
      ),
      (
        Icons.crop_free_rounded,
        AppLocalizations.of(context)!.cropAdjustAutoCrop,
        onAutoCrop,
      ),
      (
        Icons.add_rounded,
        AppLocalizations.of(context)!.cropAdjustAddPage,
        onAddPage,
      ),
    ];

    return Container(
      color: surface,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          for (final (icon, label, onTap) in items)
            Expanded(
              child: InkWell(
                onTap: enabled ? onTap : null,
                borderRadius: BorderRadius.circular(16),
                child: Opacity(
                  opacity: enabled ? 1 : 0.4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: surface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: ink, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(label, style: TextStyle(fontSize: 11, color: muted)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CornerDot extends StatelessWidget {
  const _CornerDot();

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _EdgeDot extends StatelessWidget {
  const _EdgeDot();

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  _QuadPainter({required this.points, required this.color});

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final quad = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    // Dim everything outside the selection.
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      quad,
    );
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    canvas.drawPath(quad, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawPath(
      quad,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _QuadPainter old) =>
      !listEquals(old.points, points) || old.color != color;
}

// ───────────────────────────── Image work (runs in isolates) ─────────────────────────────

Uint8List _bakeOrientation(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) throw const FormatException('Unsupported image');
  final baked = img.bakeOrientation(decoded);
  return Uint8List.fromList(img.encodeJpg(baked, quality: 95));
}

Uint8List _rotate90(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image');
  final rotated = img.copyRotate(decoded, angle: 90);
  return Uint8List.fromList(img.encodeJpg(rotated, quality: 95));
}

class _CropJob {
  const _CropJob({required this.bytes, required this.points});

  final Uint8List bytes;

  /// TL, TR, BR, BL as [x, y] in 0..1.
  final List<List<double>> points;
}

Uint8List _cropPerspective(_CropJob job) {
  final src = img.decodeImage(job.bytes);
  if (src == null) throw const FormatException('Unsupported image');

  final w = src.width.toDouble();
  final h = src.height.toDouble();
  final p = [for (final pt in job.points) Offset(pt[0] * w, pt[1] * h)];
  final tl = p[0], tr = p[1], br = p[2], bl = p[3];

  final outW = math
      .max((tr - tl).distance, (br - bl).distance)
      .round()
      .clamp(32, 6000);
  final outH = math
      .max((bl - tl).distance, (br - tr).distance)
      .round()
      .clamp(32, 8000);

  final dst = img.Image(
    width: outW,
    height: outH,
    numChannels: src.numChannels,
  );
  final result = img.copyRectify(
    src,
    topLeft: img.Point(tl.dx, tl.dy),
    topRight: img.Point(tr.dx, tr.dy),
    bottomLeft: img.Point(bl.dx, bl.dy),
    bottomRight: img.Point(br.dx, br.dy),
    interpolation: img.Interpolation.linear,
    toImage: dst,
  );
  return Uint8List.fromList(img.encodeJpg(result, quality: 92));
}
