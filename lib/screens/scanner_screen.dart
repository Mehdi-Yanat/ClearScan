import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crop_adjust_screen.dart';
import 'enhance_save_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/card_quad_detector.dart';
import '../services/document_storage.dart';
import '../services/document_quad_detector.dart';
import '../services/notification_service.dart';
import '../widgets/app_snackbar.dart';

enum ScanMode {
  idCard(1.586),
  passport(1.42),
  document(0.707),
  qr(1.0),
  book(1.414);

  const ScanMode(this.aspect);

  final double aspect;

  bool get isCard => this == ScanMode.idCard;
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
  final Map<ScanMode, String> _capturedFronts = {};
  bool _processingCardFrame = false;
  bool _cardStreamUnavailableShown = false;
  bool _cardAnalysisErrorShown = false;
  DateTime _lastCardFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _cardAnalysisGeneration = 0;
  int _stableCardFrames = 0;
  List<Offset>? _previousCardCorners;
  List<Offset>? _displayCardCorners;
  Size? _cardFrameSize;
  String? _cardGuidance;

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
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final controller = _camera;
      _camera = null;
      _resetCardTracking();
      unawaited(controller?.dispose());
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
      if (mounted) {
        setState(() {});
        if (_mode.isCard) await _startCardFrameStream(controller);
      }
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
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      _resetCardTracking();
      HapticFeedback.mediumImpact();
      final file = await controller.takePicture();
      await _handleResult(file);
    } on CameraException catch (_) {
      _showSnack('Could not take the picture. Try again.');
    } on Exception catch (error) {
      _showSnack('Could not process the captured image: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_mode.isCard && identical(_camera, controller)) {
          await _startCardFrameStream(controller);
        }
      }
    }
  }

  Future<void> _startCardFrameStream(CameraController controller) async {
    if (!mounted ||
        !_mode.isCard ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }
    try {
      await controller.startImageStream(
        (frame) => _processCardFrame(controller, frame),
      );
    } on CameraException catch (error) {
      if (!_cardStreamUnavailableShown) {
        _cardStreamUnavailableShown = true;
        _showSnack('Live card guidance unavailable; use the shutter: $error');
      }
    }
  }

  void _processCardFrame(CameraController controller, CameraImage frame) {
    final now = DateTime.now();
    if (!mounted ||
        _busy ||
        !_mode.isCard ||
        _processingCardFrame ||
        now.difference(_lastCardFrameAt).inMilliseconds < 300 ||
        frame.planes.isEmpty) {
      return;
    }
    final plane = frame.planes.first;
    final bytesPerPixel = plane.bytesPerPixel ?? 1;
    if (bytesPerPixel < 1 || plane.bytesPerRow < frame.width * bytesPerPixel) {
      return;
    }
    final lastByte =
        (frame.height - 1) * plane.bytesPerRow +
        (frame.width - 1) * bytesPerPixel;
    if (frame.width < 1 || frame.height < 1 || lastByte >= plane.bytes.length) {
      return;
    }
    _processingCardFrame = true;
    _lastCardFrameAt = now;
    _cardFrameSize = Size(frame.width.toDouble(), frame.height.toDouble());
    final mode = _mode;
    final generation = _cardAnalysisGeneration;
    unawaited(
      _assessCardFrame(
        controller,
        mode,
        generation,
        CardFrameInput(
          luminanceBytes: Uint8List.fromList(plane.bytes),
          width: frame.width,
          height: frame.height,
          bytesPerRow: plane.bytesPerRow,
          bytesPerPixel: bytesPerPixel,
        ),
      ),
    );
  }

  Future<void> _assessCardFrame(
    CameraController controller,
    ScanMode mode,
    int generation,
    CardFrameInput input,
  ) async {
    try {
      final assessment = await CardQuadDetector.assessFrame(
        input,
        targetAspectRatio: mode.aspect,
      );
      if (!mounted ||
          !identical(_camera, controller) ||
          _mode != mode ||
          generation != _cardAnalysisGeneration) {
        return;
      }
      final guidance = _guidanceForCardFrame(assessment, mode);
      final corners = assessment.corners;
      final nearBoundary =
          corners != null &&
          corners.any(
            (point) =>
                point.dx <= 0.12 ||
                point.dx >= 0.88 ||
                point.dy <= 0.12 ||
                point.dy >= 0.88,
          );
      final stable =
          corners != null &&
          !nearBoundary &&
          assessment.confidence >= 0.52 &&
          assessment.areaRatio >= 0.025 &&
          assessment.areaRatio <= 0.62 &&
          assessment.sharpness >= 18 &&
          assessment.glareRatio <= 0.18 &&
          assessment.brightness >= 38 &&
          _cornersAreStable(corners, _previousCardCorners);
      if (stable) {
        _stableCardFrames++;
      } else {
        _stableCardFrames = 0;
      }
      _previousCardCorners = corners;
      _displayCardCorners = _smoothCorners(corners, _displayCardCorners);
      if (_cardGuidance != guidance) {
        setState(() => _cardGuidance = guidance);
      } else {
        setState(() {});
      }
      if (_stableCardFrames >= 5 && !_busy) {
        unawaited(_capture());
      }
    } on Exception catch (error) {
      if (generation == _cardAnalysisGeneration) _resetCardTracking();
      if (mounted && !_cardAnalysisErrorShown) {
        _cardAnalysisErrorShown = true;
        _showSnack('Could not analyze the card preview: $error');
      }
    } finally {
      if (generation == _cardAnalysisGeneration) {
        _processingCardFrame = false;
      }
    }
  }

  String _guidanceForCardFrame(CardFrameAssessment assessment, ScanMode mode) {
    final l10n = AppLocalizations.of(context)!;
    if (assessment.corners == null) return l10n.scanGuidanceKeepInFrame;
    if (assessment.corners!.any(
      (point) =>
          point.dx <= 0.12 ||
          point.dx >= 0.88 ||
          point.dy <= 0.12 ||
          point.dy >= 0.88,
    )) {
      return l10n.scanGuidanceMoveAwayFromEdge;
    }
    if (assessment.sharpness < 18) return l10n.scanGuidanceHoldSteady;
    if (assessment.glareRatio > 0.18) return l10n.scanGuidanceReduceGlare;
    if (assessment.brightness < 38) return l10n.scanGuidanceImproveLighting;
    if (assessment.areaRatio < 0.025) return l10n.scanGuidanceMoveCloser;
    if (assessment.areaRatio > 0.62) return l10n.scanGuidanceMoveBack;
    return _capturedFronts.containsKey(mode)
        ? l10n.scanModeBackSideHint
        : l10n.scanGuidanceAlignCard;
  }

  bool _cornersAreStable(List<Offset> current, List<Offset>? previous) {
    if (previous == null || previous.length != current.length) return false;
    final meanMovement =
        List.generate(
          current.length,
          (index) => (current[index] - previous[index]).distance,
        ).reduce((a, b) => a + b) /
        current.length;
    return meanMovement < 0.012;
  }

  List<Offset>? _smoothCorners(List<Offset>? current, List<Offset>? previous) {
    if (current == null) return null;
    if (previous == null || !_cornersAreStable(current, previous)) {
      return current;
    }
    return [
      for (var i = 0; i < current.length; i++)
        Offset.lerp(previous[i], current[i], 0.35)!,
    ];
  }

  void _resetCardTracking() {
    _cardAnalysisGeneration++;
    _stableCardFrames = 0;
    _previousCardCorners = null;
    _displayCardCorners = null;
    _cardFrameSize = null;
    _processingCardFrame = false;
  }

  Future<void> _changeMode(ScanMode mode) async {
    if (_mode == mode) return;
    final controller = _camera;
    _resetCardTracking();
    try {
      if (_mode.isCard != mode.isCard &&
          controller?.value.isStreamingImages == true) {
        await controller!.stopImageStream();
      }
      setState(() => _mode = mode);
      if (mode.isCard && controller != null) {
        await _startCardFrameStream(controller);
      }
    } on CameraException catch (error) {
      _showSnack('Could not change scan mode (${error.code}).');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null) await _handleResult(file);
    } on Exception catch (error) {
      _showSnack('Could not select an image: $error');
    }
  }

  Future<void> _handleResult(XFile file) async {
    if (!mounted) return;
    String? preparedImagePath;
    if (_isTwoSidedMode(_mode)) {
      final croppedPath = await _cropImage(file.path);
      if (!mounted || croppedPath == null) return;

      final frontPath = _capturedFronts[_mode];
      if (frontPath == null) {
        setState(() => _capturedFronts[_mode] = croppedPath);
        return;
      }

      final combinedFile = await _combineIdSides(frontPath, croppedPath);
      setState(() => _capturedFronts.remove(_mode));
      file = XFile(combinedFile.path);
      preparedImagePath = combinedFile.path;
    }

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

    final imagePath = preparedImagePath ?? await _cropImage(file.path);
    if (!mounted || imagePath == null) return;

    try {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => EnhanceSaveScreen(
            imagePath: imagePath,
            initialFileName: _getScanModeLabel(_mode),
            targetAspectRatio: _mode.aspect,
            detectionMode: _mode.isCard
                ? DocumentDetectionMode.card
                : DocumentDetectionMode.paper,
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

  bool _isTwoSidedMode(ScanMode mode) => switch (mode) {
    ScanMode.idCard => true,
    _ => false,
  };

  Future<String?> _cropImage(String imagePath) async {
    final result = await Navigator.of(context).push<CropResult>(
      MaterialPageRoute<CropResult>(
        builder: (_) => CropAdjustScreen(
          imagePath: imagePath,
          targetAspectRatio: _mode.aspect,
          detectionMode: _mode.isCard
              ? DocumentDetectionMode.card
              : DocumentDetectionMode.paper,
        ),
      ),
    );
    return result?.path;
  }

  Future<File> _combineIdSides(String frontPath, String backPath) async {
    final frontBytes = await File(frontPath).readAsBytes();
    final backBytes = await File(backPath).readAsBytes();
    final combinedBytes = await compute(_combineImageBytes, <Uint8List>[
      frontBytes,
      backBytes,
    ]);
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/id_scan_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(combinedBytes, flush: true);
    return file;
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
          return 'ID';
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
          return _capturedFronts.containsKey(mode)
              ? 'Front captured. Turn it over and capture the back.'
              : 'Capture the front and back of your national ID; both sides are saved together.';
        case ScanMode.passport:
          return 'Frame the identity-information page with all edges visible';
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
        return _capturedFronts.containsKey(mode)
            ? localizations.scanModeBackSideHint
            : localizations.scanModeIdCardHint;
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
            if (_mode.isCard && _displayCardCorners != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CardQuadPainter(
                      corners: _displayCardCorners!,
                      frameSize: _cardFrameSize,
                      color: _accent,
                    ),
                  ),
                ),
              ),
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
                    _HintPill(
                      text: _mode.isCard
                          ? _cardGuidance ??
                                AppLocalizations.of(context)!
                                    .scanGuidanceAlignCard
                          : _getScanModeHint(_mode),
                    ),
                    const SizedBox(height: 18),
                    _ModeSelector(
                      selected: _mode,
                      accent: _accent,
                      onChanged: _changeMode,
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

class _CardQuadPainter extends CustomPainter {
  const _CardQuadPainter({
    required this.corners,
    required this.frameSize,
    required this.color,
  });

  final List<Offset> corners;
  final Size? frameSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = frameSize;
    if (frame == null || frame.width <= 0 || frame.height <= 0) return;
    final imageAspect = frame.height / frame.width;
    final viewportAspect = size.width / size.height;
    final visibleWidth = imageAspect > viewportAspect
        ? viewportAspect / imageAspect
        : 1.0;
    final visibleHeight = imageAspect > viewportAspect
        ? 1.0
        : imageAspect / viewportAspect;
    final offsetX = (1 - visibleWidth) / 2;
    final offsetY = (1 - visibleHeight) / 2;
    final points = [
      for (final corner in corners)
        Offset(
          ((1 - corner.dy) - offsetX) / visibleWidth * size.width,
          (corner.dx - offsetY) / visibleHeight * size.height,
        ),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CardQuadPainter oldDelegate) =>
      oldDelegate.corners != corners ||
      oldDelegate.frameSize != frameSize ||
      oldDelegate.color != color;
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
          return 'ID';
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final mode in ScanMode.values)
            InkWell(
              onTap: () => onChanged(mode),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getModeLabel(mode, context),
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: mode == selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: mode == selected ? accent : unselectedColor,
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

Uint8List _combineImageBytes(List<Uint8List> sides) {
  final front = img.decodeImage(sides[0]);
  final back = img.decodeImage(sides[1]);
  if (front == null || back == null) {
    throw const FormatException('Could not read both captured document sides.');
  }

  final width = front.width > back.width ? front.width : back.width;
  final frontImage = front.width == width
      ? front
      : img.copyResize(
          front,
          width: width,
          interpolation: img.Interpolation.average,
        );
  final backImage = back.width == width
      ? back
      : img.copyResize(
          back,
          width: width,
          interpolation: img.Interpolation.average,
        );
  final combined = img.Image(
    width: width,
    height: frontImage.height + backImage.height,
    numChannels: 3,
  );
  img.compositeImage(combined, frontImage, dstX: 0, dstY: 0);
  img.compositeImage(combined, backImage, dstX: 0, dstY: frontImage.height);
  return Uint8List.fromList(img.encodeJpg(combined, quality: 95));
}
