import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crop_adjust_screen.dart';
import 'enhance_save_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/document_storage.dart';
import '../services/notification_service.dart';
import '../widgets/app_snackbar.dart';

enum ScanMode {
  idCard(1.586),
  passport(0.72),
  document(0.707),
  qr(1.0),
  book(1.414);

  const ScanMode(this.aspect);

  final double aspect;
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    this.onCaptured,
    this.initialMode = ScanMode.document,
  });

  /// Called with the captured / picked image. Use it to open the crop screen.
  /// If null, a placeholder snackbar is shown.
  final void Function(XFile file, String mode)? onCaptured;

  final ScanMode initialMode;

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

  late ScanMode _mode = widget.initialMode;
  int _flashIndex = 0;
  bool _showGrid = false;
  String _quality = AppSettings.defaultQuality;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadScannerSettings();
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

  Future<void> _loadScannerSettings() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _showGrid = preferences.getBool(AppSettings.grid) ?? false;
        _quality =
            preferences.getString(AppSettings.quality) ??
            AppSettings.defaultQuality;
      });
    } on Exception catch (error) {
      _showSnack('Could not load scanner settings: $error');
    }
    if (mounted) await _initCamera();
  }

  ResolutionPreset _resolutionForQuality(String quality) {
    final l10n = AppLocalizations.of(context);
    if (quality == l10n?.settingsQualityLow ||
        quality.toLowerCase() == 'low' ||
        quality.toLowerCase() == 'niedrig' ||
        quality == 'منخفضة') {
      return ResolutionPreset.medium;
    }
    if (quality == l10n?.settingsQualityMedium ||
        quality.toLowerCase() == 'medium' ||
        quality.toLowerCase() == 'mittel' ||
        quality == 'متوسطة') {
      return ResolutionPreset.high;
    }
    return ResolutionPreset.veryHigh;
  }

  Future<void> _savePreference(
    String key,
    Object value,
    String errorMessage,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = switch (value) {
        bool boolean => await preferences.setBool(key, boolean),
        String text => await preferences.setString(key, text),
        _ => false,
      };
      if (!saved) throw Exception('Preference write was rejected.');
    } on Exception catch (error) {
      _showSnack('$errorMessage: $error');
    }
  }

  Future<void> _setGrid(bool enabled) async {
    setState(() => _showGrid = enabled);
    await _savePreference(
      AppSettings.grid,
      enabled,
      'Could not save grid setting',
    );
  }

  Future<void> _setQuality(String quality) async {
    if (_quality == quality) return;
    setState(() => _quality = quality);
    await _savePreference(
      AppSettings.quality,
      quality,
      'Could not save scan quality',
    );
    final oldCamera = _camera;
    _camera = null;
    _initFuture = null;
    await oldCamera?.dispose();
    if (mounted) await _initCamera();
  }

  Future<void> _showScannerSettings() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final qualityOptions = <String>[
      l10n.settingsQualityLow,
      l10n.settingsQualityMedium,
      l10n.settingsQualityHigh,
    ];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, updateSheet) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 18, 8, 6),
                    child: Text(
                      l10n.settingsSectionScanning,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(l10n.scannerGrid),
                    value: _showGrid,
                    onChanged: (value) {
                      _setGrid(value);
                      updateSheet(() {});
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Text(
                      l10n.settingsDefaultQuality,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final option in qualityOptions)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(option),
                      trailing: option == _quality
                          ? Icon(
                              Icons.check_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        _setQuality(option);
                        updateSheet(() {});
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _initCamera() async {
    if (!mounted) return;
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
        _resolutionForQuality(_quality),
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
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
      await _handleResult(file);
    } on CameraException catch (_) {
      _showSnack('Could not take the picture. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) await _handleResult(file);
  }

  Future<void> _handleResult(XFile file) async {
    if (!mounted) return;
    final callback = widget.onCaptured;
    if (callback != null) {
      try {
        await addNotification(
          AppNotificationType.scanCompleted,
          detail: _getScanModeLabel(_mode),
        );
      } on Exception catch (error) {
        _showSnack('Could not save the scan notification: $error');
      }
      callback(file, _getScanModeLabel(_mode));
      return;
    }

    final result = await Navigator.of(context).push<CropResult>(
      MaterialPageRoute<CropResult>(
        builder: (_) => CropAdjustScreen(imagePath: file.path),
      ),
    );
    if (!mounted || result?.path == null) return;

    try {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => EnhanceSaveScreen(
            imagePath: result!.path!,
            initialFileName: _getScanModeLabel(_mode),
            onSave: (imageBytes, fileName, format) async {
              final String savedName;
              if (format.toUpperCase() == 'PDF') {
                final saved = await saveEnhancedPdfToDevice(
                  imageBytes: imageBytes,
                  name: fileName,
                );
                savedName = saved.filename;
              } else {
                final saved = await saveEnhancedDocument(
                  imageBytes: imageBytes,
                  name: fileName,
                  format: format,
                );
                savedName = saved.uri.pathSegments.last;
              }
              if (!mounted) return;
              _showSnack('Saved $savedName');
              try {
                await addNotification(
                  AppNotificationType.scanCompleted,
                  detail: savedName,
                );
              } on Exception catch (error) {
                _showSnack('Could not save the scan notification: $error');
              }
            },
          ),
        ),
      );
    } on Exception catch (error) {
      _showSnack('Could not open the enhance screen: $error');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    showAppSnackBar(context, message);
  }

  IconData get _flashIcon => switch (_flashModes[_flashIndex]) {
    FlashMode.auto => Icons.flash_auto_rounded,
    FlashMode.always => Icons.flash_on_rounded,
    _ => Icons.flash_off_rounded,
  };

  String _getScanModeLabel(ScanMode mode) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Fallback to English if localizations is not available
      switch (mode) {
        case ScanMode.idCard:
          return 'ID Card';
        case ScanMode.passport:
          return 'Passport';
        case ScanMode.document:
          return 'Document';
        case ScanMode.qr:
          return 'QR Code';
        case ScanMode.book:
          return 'Book';
      }
    }
    // Localizations is not null here
    switch (mode) {
      case ScanMode.idCard:
        return localizations.scanModeIdCardLabel;
      case ScanMode.passport:
        return localizations.scanModePassportLabel;
      case ScanMode.document:
        return localizations.scanModeDocumentLabel;
      case ScanMode.qr:
        return localizations.scanModeQrLabel;
      case ScanMode.book:
        return localizations.scanModeBookLabel;
    }
  }

  String _getScanModeHint(ScanMode mode) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Fallback to English if localizations is not available
      switch (mode) {
        case ScanMode.idCard:
          return 'Place your ID card inside the frame';
        case ScanMode.passport:
          return 'Align the photo page with the frame';
        case ScanMode.document:
          return 'Align the document with the frame';
        case ScanMode.qr:
          return 'Point your camera at a QR code';
        case ScanMode.book:
          return 'Open the book and fit both pages in the frame';
      }
    }
    // Localizations is not null here
    switch (mode) {
      case ScanMode.idCard:
        return localizations.scanModeIdCardHint;
      case ScanMode.passport:
        return localizations.scanModePassportHint;
      case ScanMode.document:
        return localizations.scanModeDocumentHint;
      case ScanMode.qr:
        return localizations.scanModeQrHint;
      case ScanMode.book:
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
                      onSettings: _showScannerSettings,
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
                            showGrid: _showGrid,
                          ),
                        ),
                      ),
                    ),
                    _HintPill(text: _getScanModeHint(_mode)),
                    const SizedBox(height: 18),
                    _ModeSelector(
                      selected: _mode,
                      accent: _accent,
                      onChanged: (m) {
                        setState(() => _mode = m);
                      },
                    ),
                    const SizedBox(height: 18),
                    _Controls(
                      busy: _busy,
                      showShutter: _mode != ScanMode.qr,
                      onGallery: _pickFromGallery,
                      onShutter: _capture,
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
  _ScanFramePainter({
    required this.aspect,
    required this.color,
    required this.showGrid,
  });

  final double aspect;
  final Color color;
  final bool showGrid;

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
    final frame = _frame(size);
    final rrect = RRect.fromRectAndRadius(frame, const Radius.circular(8));

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

    if (showGrid) {
      canvas.save();
      canvas.clipRRect(rrect);
      final gridPaint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = 1;
      for (var i = 1; i < 3; i++) {
        final x = frame.left + frame.width * i / 3;
        final y = frame.top + frame.height * i / 3;
        canvas.drawLine(
          Offset(x, frame.top),
          Offset(x, frame.bottom),
          gridPaint,
        );
        canvas.drawLine(
          Offset(frame.left, y),
          Offset(frame.right, y),
          gridPaint,
        );
      }
      canvas.restore();
    }

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

    canvas.drawPath(corner(frame.topLeft, 1, 1), paint);
    canvas.drawPath(corner(frame.topRight, -1, 1), paint);
    canvas.drawPath(corner(frame.bottomLeft, 1, -1), paint);
    canvas.drawPath(corner(frame.bottomRight, -1, -1), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter old) =>
      old.aspect != aspect || old.color != color || old.showGrid != showGrid;
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

  final ScanMode selected;
  final Color accent;
  final ValueChanged<ScanMode> onChanged;

  String _getModeLabel(ScanMode mode, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Fallback to English if localizations is not available
      switch (mode) {
        case ScanMode.idCard:
          return 'ID Card';
        case ScanMode.passport:
          return 'Passport';
        case ScanMode.document:
          return 'Document';
        case ScanMode.qr:
          return 'QR Code';
        case ScanMode.book:
          return 'Book';
      }
    }
    // Localizations is not null here
    switch (mode) {
      case ScanMode.idCard:
        return localizations.scanModeIdCardLabel;
      case ScanMode.passport:
        return localizations.scanModePassportLabel;
      case ScanMode.document:
        return localizations.scanModeDocumentLabel;
      case ScanMode.qr:
        return localizations.scanModeQrLabel;
      case ScanMode.book:
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
          for (final mode in ScanMode.values)
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
    required this.onGallery,
    required this.onShutter,
  });

  final bool busy;
  final bool showShutter;
  final VoidCallback onGallery;
  final VoidCallback onShutter;

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
          Expanded(
            child: Center(
              child: AnimatedOpacity(
                opacity: showShutter ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(
                  ignoring: !showShutter,
                  child: _Shutter(busy: busy, onTap: onShutter),
                ),
              ),
            ),
          ),
          const SizedBox(width: 52),
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
