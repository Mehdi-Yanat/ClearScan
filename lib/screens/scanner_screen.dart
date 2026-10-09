import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';

enum _ScanMode {
  idCard(1.586),
  passport(0.72),
  document(0.707),
  qr(1.0),
  book(1.35);

  const _ScanMode(this.aspect);

  final double aspect;
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.onCaptured});

  /// Called with the captured / picked image. Use it to open the crop screen.
  /// If null, a placeholder snackbar is shown.
  final void Function(XFile file, String mode)? onCaptured;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  static const _accent = Color(0xFF2CC4CF);
  static const _flashModes = [FlashMode.auto, FlashMode.always, FlashMode.off];

  CameraController? _camera;
  Future<void>? _initFuture;
  String? _error;

  _ScanMode _mode = _ScanMode.document;
  int _flashIndex = 0;
  bool _autoCapture = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _camera;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() => _error = null);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _camera = controller;
      _initFuture = controller.initialize().then((_) async {
        await controller.setFlashMode(_flashModes[_flashIndex]);
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      });
      setState(() {});
      await _initFuture;
      if (mounted) setState(() {});
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            e.code == 'CameraAccessDenied' ||
                e.code == 'CameraAccessDeniedWithoutPrompt'
            ? 'Camera permission is required to scan documents.'
            : 'Could not start the camera (${e.code}).';
      });
    }
  }

  Future<void> _cycleFlash() async {
    final controller = _camera;
    if (controller == null || !controller.value.isInitialized) return;
    final next = (_flashIndex + 1) % _flashModes.length;
    setState(() => _flashIndex = next);
    await controller.setFlashMode(_flashModes[next]);
  }

  Future<void> _capture() async {
    final controller = _camera;
    if (_busy || controller == null || !controller.value.isInitialized) return;
    setState(() => _busy = true);
    try {
      HapticFeedback.mediumImpact();
      final file = await controller.takePicture();
      _handleResult(file);
    } on CameraException catch (_) {
      _showSnack('Could not take the picture. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) _handleResult(file);
  }

  void _handleResult(XFile file) {
    if (!mounted) return;
    final callback = widget.onCaptured;
    if (callback != null) {
      callback(file, _getScanModeLabel(_mode));
    } else {
      // TODO: push the crop / adjust-edges screen with [file].
      _showSnack('Captured: ${file.path.split('/').last}');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  IconData get _flashIcon => switch (_flashModes[_flashIndex]) {
    FlashMode.auto => Icons.flash_auto_rounded,
    FlashMode.always => Icons.flash_on_rounded,
    _ => Icons.flash_off_rounded,
  };

  String _getScanModeLabel(_ScanMode mode) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Fallback to English if localizations is not available
      switch (mode) {
        case _ScanMode.idCard:
          return 'ID Card';
        case _ScanMode.passport:
          return 'Passport';
        case _ScanMode.document:
          return 'Document';
        case _ScanMode.qr:
          return 'QR Code';
        case _ScanMode.book:
          return 'Book';
      }
    }
    // Localizations is not null here
    switch (mode) {
      case _ScanMode.idCard:
        return localizations.scanModeIdCardLabel;
      case _ScanMode.passport:
        return localizations.scanModePassportLabel;
      case _ScanMode.document:
        return localizations.scanModeDocumentLabel;
      case _ScanMode.qr:
        return localizations.scanModeQrLabel;
      case _ScanMode.book:
        return localizations.scanModeBookLabel;
    }
  }

  String _getScanModeHint(_ScanMode mode) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Fallback to English if localizations is not available
      switch (mode) {
        case _ScanMode.idCard:
          return 'Place your ID card inside the frame';
        case _ScanMode.passport:
          return 'Align the photo page with the frame';
        case _ScanMode.document:
          return 'Align the document with the frame';
        case _ScanMode.qr:
          return 'Point your camera at a QR code';
        case _ScanMode.book:
          return 'Open the book and fit both pages in the frame';
      }
    }
    // Localizations is not null here
    switch (mode) {
      case _ScanMode.idCard:
        return localizations.scanModeIdCardHint;
      case _ScanMode.passport:
        return localizations.scanModePassportHint;
      case _ScanMode.document:
        return localizations.scanModeDocumentHint;
      case _ScanMode.qr:
        return localizations.scanModeQrHint;
      case _ScanMode.book:
        return localizations.scanModeBookHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Camera screens are typically dark regardless of theme
    // But we can use a slightly adaptive background
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scannerBg = isDark
        ? const Color(0xFF0A1418)
        : const Color(0xFF1A1A1A);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: scannerBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: scannerBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildPreview(context),
            // Dim + frame + corner brackets
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      flashIcon: _flashIcon,
                      onClose: () =>
                          Navigator.of(context).pushReplacementNamed('/home'),
                      onFlash: _cycleFlash,
                      onSettings: () {
                        // TODO: scanner settings (quality, grid, auto-capture)
                      },
                    ),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: _mode.aspect),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        builder: (context, aspect, _) => CustomPaint(
                          size: Size.infinite,
                          painter: _ScanFramePainter(
                            aspect: aspect,
                            color: _accent,
                          ),
                        ),
                      ),
                    ),
                    _HintPill(text: _getScanModeHint(_mode)),
                    const SizedBox(height: 18),
                    _ModeSelector(
                      selected: _mode,
                      accent: _accent,
                      onChanged: (m) => setState(() => _mode = m),
                    ),
                    const SizedBox(height: 18),
                    _Controls(
                      busy: _busy,
                      showShutter: _mode != _ScanMode.qr,
                      autoCapture: _autoCapture,
                      onGallery: _pickFromGallery,
                      onShutter: _capture,
                      onToggleAuto: () =>
                          setState(() => _autoCapture = !_autoCapture),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // ✅ Fixed
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _camera;
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: primaryColor, // ✅ Fixed
        ),
      );
    }

    final size = controller.value.previewSize!;
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            // previewSize is reported in landscape; swap for a portrait UI.
            width: size.height,
            height: size.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Top bar ─────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.flashIcon,
    required this.onClose,
    required this.onFlash,
    required this.onSettings,
  });

  final IconData flashIcon;
  final VoidCallback onClose;
  final VoidCallback onFlash;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 26,
            ),
            tooltip: 'Close',
          ),
          const Spacer(),
          IconButton(
            onPressed: onFlash,
            icon: Icon(flashIcon, color: Colors.white, size: 24),
            tooltip: 'Flash',
          ),
          IconButton(
            onPressed: onSettings,
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 23,
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Frame overlay ─────────────────────────────

class _ScanFramePainter extends CustomPainter {
  _ScanFramePainter({required this.aspect, required this.color});

  final double aspect;
  final Color color;

  Rect _frame(Size size) {
    final maxW = size.width * 0.8;
    final maxH = size.height * 0.94;
    var w = maxW;
    var h = w / aspect;
    if (h > maxH) {
      h = maxH;
      w = h * aspect;
    }
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = _frame(size);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Darken everything outside the frame.
    final dim = Path.combine(
      PathOperation.difference,
      Path()..addRect(
        Rect.fromLTWH(-400, -400, size.width + 800, size.height + 800),
      ),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.42));

    // Soft fill inside.
    canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: 0.08));

    // Corner brackets.
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const len = 34.0;

    Path corner(Offset c, double dx, double dy) => Path()
      ..moveTo(c.dx, c.dy + len * dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(c.dx + len * dx, c.dy);

    canvas.drawPath(corner(rect.topLeft, 1, 1), paint);
    canvas.drawPath(corner(rect.topRight, -1, 1), paint);
    canvas.drawPath(corner(rect.bottomLeft, 1, -1), paint);
    canvas.drawPath(corner(rect.bottomRight, -1, -1), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter old) =>
      old.aspect != aspect || old.color != color;
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ───────────────────────────── Mode selector ─────────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  final _ScanMode selected;
  final Color accent;
  final ValueChanged<_ScanMode> onChanged;

  String _getModeLabel(_ScanMode mode, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Fallback to English if localizations is not available
      switch (mode) {
        case _ScanMode.idCard:
          return 'ID Card';
        case _ScanMode.passport:
          return 'Passport';
        case _ScanMode.document:
          return 'Document';
        case _ScanMode.qr:
          return 'QR Code';
        case _ScanMode.book:
          return 'Book';
      }
    }
    // Localizations is not null here
    switch (mode) {
      case _ScanMode.idCard:
        return localizations.scanModeIdCardLabel;
      case _ScanMode.passport:
        return localizations.scanModePassportLabel;
      case _ScanMode.document:
        return localizations.scanModeDocumentLabel;
      case _ScanMode.qr:
        return localizations.scanModeQrLabel;
      case _ScanMode.book:
        return localizations.scanModeBookLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use theme-aware muted color for unselected items
    final unselectedColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB7C4CA)
        : const Color(0xFF9AA8B0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final mode in _ScanMode.values)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(mode),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getModeLabel(mode, context),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: mode == selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: mode == selected
                              ? accent
                              : unselectedColor, // ✅ Fixed
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: mode == selected ? 26 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
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

// ───────────────────────────── Bottom controls ─────────────────────────────

class _Controls extends StatelessWidget {
  const _Controls({
    required this.busy,
    required this.showShutter,
    required this.autoCapture,
    required this.onGallery,
    required this.onShutter,
    required this.onToggleAuto,
  });

  final bool busy;
  final bool showShutter;
  final bool autoCapture;
  final VoidCallback onGallery;
  final VoidCallback onShutter;
  final VoidCallback onToggleAuto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassButton(
            onTap: onGallery,
            radius: 14,
            child: const Icon(
              Icons.photo_library_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          AnimatedOpacity(
            opacity: showShutter ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: IgnorePointer(
              ignoring: !showShutter,
              child: _Shutter(busy: busy, onTap: onShutter),
            ),
          ),
          _GlassButton(
            onTap: onToggleAuto,
            radius: 26,
            child: Text(
              autoCapture ? 'Auto' : 'Manual',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.onTap,
    required this.child,
    required this.radius,
  });

  final VoidCallback onTap;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: SizedBox(width: 52, height: 52, child: Center(child: child)),
      ),
    );
  }
}

class _Shutter extends StatefulWidget {
  const _Shutter({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  State<_Shutter> createState() => _ShutterState();
}

class _ShutterState extends State<_Shutter> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.busy ? null : widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.busy ? Colors.white54 : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
