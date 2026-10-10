import 'dart:async';
import 'dart:io';

import 'package:clear_scan/services/document_filters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'crop_adjust_screen.dart';
import '../services/document_quad_detector.dart';
import '../services/document_storage.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/share_sheet.dart';

class EnhanceSaveScreen extends StatefulWidget {
  const EnhanceSaveScreen({
    super.key,
    required this.imagePath,
    this.initialFileName = 'Scanned_Document',
    this.targetAspectRatio,
    this.detectionMode = DocumentDetectionMode.paper,
    this.onSave,
    this.onAddPage,
  });

  final String imagePath;
  final String initialFileName;
  final double? targetAspectRatio;
  final DocumentDetectionMode detectionMode;
  final Future<void> Function(
    Uint8List imageBytes,
    String fileName,
    String format,
  )?
  onSave;
  final VoidCallback? onAddPage;

  @override
  State<EnhanceSaveScreen> createState() => _EnhanceSaveScreenState();
}

class _EnhanceSaveScreenState extends State<EnhanceSaveScreen> {
  double _brightness = 0.5;
  double _contrast = 0.5;
  late String _imagePath;
  final TextEditingController _fileNameController = TextEditingController();
  bool _saving = false;

  // Live preview: a small, pre-rotated copy of the image is filtered in an
  // isolate with the same pipeline used for saving.
  Uint8List? _previewSource;
  Uint8List? _previewBytes;
  Timer? _debounce;
  int _previewGeneration = 0;
  int _sourceGeneration = 0;
  bool _previewBusy = false;

  final List<_FilterOption> _filters = [
    _FilterOption(
      type: DocFilter.original,
      label: 'Original',
      color: Colors.white,
      iconColor: const Color(0xFF9AA8B0),
    ),
    _FilterOption(
      type: DocFilter.magic,
      label: 'Magic',
      color: const Color(0xFFFFF3D6),
      iconColor: const Color(0xFF14909A),
      isSelected: true,
    ),
    _FilterOption(
      type: DocFilter.bw,
      label: 'B&W',
      color: const Color(0xFFE8E8E8),
      iconColor: const Color(0xFF6B7C85),
    ),
    _FilterOption(
      type: DocFilter.gray,
      label: 'Gray',
      color: const Color(0xFFD1D1D1),
      iconColor: const Color(0xFF6B7C85),
    ),
    _FilterOption(
      type: DocFilter.vivid,
      label: 'Vivid',
      color: const Color(0xFFD4F1F3),
      iconColor: const Color(0xFF14909A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _imagePath = widget.imagePath;
    _fileNameController.text = widget.initialFileName;
    _loadPreviewSource(_imagePath);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fileNameController.dispose();
    super.dispose();
  }

  DocFilter get _selectedFilter =>
      _filters.firstWhere((filter) => filter.isSelected).type;

  EnhanceJob _jobFor(
    Uint8List bytes, {
    int maxSide = kSaveMaxSide,
    int quality = 92,
  }) => EnhanceJob(
    bytes: bytes,
    filter: _selectedFilter,
    brightness: _brightness,
    contrast: _contrast,
    maxSide: maxSide,
    quality: quality,
  );

  Future<void> _loadPreviewSource(String imagePath) async {
    final generation = ++_sourceGeneration;
    try {
      final bytes = await File(imagePath).readAsBytes();
      final small = await compute(makePreviewSource, bytes);
      if (!mounted || generation != _sourceGeneration) return;
      _previewSource = small;
      _schedulePreview(immediate: true);
    } catch (_) {
      // The original image stays visible; saving still works.
    }
  }

  Future<void> _openCropScreen() async {
    final result = await Navigator.of(context).push<CropResult>(
      MaterialPageRoute<CropResult>(
        builder: (_) => CropAdjustScreen(
          imagePath: _imagePath,
          targetAspectRatio: widget.targetAspectRatio,
          detectionMode: widget.detectionMode,
        ),
      ),
    );
    if (!mounted || result?.path == null) return;

    setState(() {
      _imagePath = result!.path!;
      _previewSource = null;
      _previewBytes = null;
      _previewBusy = false;
      _previewGeneration++;
    });
    await _loadPreviewSource(_imagePath);
  }

  void _schedulePreview({bool immediate = false}) {
    _debounce?.cancel();
    _debounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 120),
      _renderPreview,
    );
  }

  Future<void> _renderPreview() async {
    final source = _previewSource;
    if (source == null) return;
    final generation = ++_previewGeneration;
    setState(() => _previewBusy = true);
    try {
      final bytes = await compute(
        processDocument,
        _jobFor(source, maxSide: kPreviewMaxSide, quality: 80),
      );
      // Ignore results from an older slider position.
      if (!mounted || generation != _previewGeneration) return;
      setState(() {
        _previewBytes = bytes;
        _previewBusy = false;
      });
    } catch (_) {
      if (mounted && generation == _previewGeneration) {
        setState(() => _previewBusy = false);
      }
    }
  }

  void _onFilterSelected(DocFilter type) {
    setState(() {
      for (var filter in _filters) {
        filter.isSelected = filter.type == type;
      }
    });
    _schedulePreview(immediate: true);
  }

  Future<void> _onExportPdf() async {
    if (_saving) return;
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) {
      _showSnackBar('Please enter a file name');
      return;
    }

    final action = await showShareSheet(
      context,
      title: 'Export PDF',
      shareLabel: 'Share PDF',
      exportLabel: 'Save PDF to Downloads',
      fileType: 'PDF',
      pageCount: 1,
      previewBytes: _previewBytes,
      previewImagePath: _imagePath,
    );
    if (!mounted || action == null) return;

    setState(() => _saving = true);
    try {
      final sourceBytes = await File(_imagePath).readAsBytes();
      final enhancedBytes = await compute(
        processDocument,
        _jobFor(sourceBytes),
      );
      if (action == ShareSheetAction.export) {
        if (widget.onSave != null) {
          await widget.onSave!(enhancedBytes, fileName, 'PDF');
        } else {
          await saveEnhancedPdfToDevice(
            imageBytes: enhancedBytes,
            name: fileName,
          );
        }
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final pdfBytes = await createPdfFromImage(enhancedBytes);
        final tempDir = await getTemporaryDirectory();
        final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final pdfName = safeName.toLowerCase().endsWith('.pdf')
            ? safeName
            : '$safeName.pdf';
        final pdfFile = File('${tempDir.path}/$pdfName');
        await pdfFile.writeAsBytes(pdfBytes, flush: true);
        try {
          await SharePlus.instance.share(
            ShareParams(files: [XFile(pdfFile.path)], subject: pdfName),
          );
        } finally {
          try {
            await pdfFile.delete();
          } on FileSystemException catch (error) {
            debugPrint('Could not remove temporary PDF: $error');
          }
        }
      }
    } catch (error) {
      _showSnackBar('Could not export the PDF: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onAddPage() {
    if (widget.onAddPage != null) {
      widget.onAddPage!();
    } else {
      _showSnackBar('Add page functionality');
    }
  }

  void _showSnackBar(String message) {
    showAppSnackBar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: bgColor,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: bgColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context, textColor),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Document Preview
                      _buildDocumentPreview(surfaceColor),

                      const SizedBox(height: 32),

                      // Filters Section
                      _buildFiltersSection(textColor, mutedColor),

                      const SizedBox(height: 32),

                      // Brightness Slider
                      _buildSliderRow(
                        label: 'Brightness',
                        value: _brightness,
                        onChanged: (v) {
                          setState(() => _brightness = v);
                          _schedulePreview();
                        },
                        textColor: textColor,
                      ),

                      const SizedBox(height: 24),

                      // Contrast Slider
                      _buildSliderRow(
                        label: 'Contrast',
                        value: _contrast,
                        onChanged: (v) {
                          setState(() => _contrast = v);
                          _schedulePreview();
                        },
                        textColor: textColor,
                      ),

                      const SizedBox(height: 32),

                      // Filename Input
                      _buildFileNameInput(surfaceColor, textColor, mutedColor),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom Buttons
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textColor,
              size: 22,
            ),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Text(
            'Enhance & Save',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(Color surfaceColor) {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Cropped document preview
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_previewBytes != null)
                      Image.memory(
                        _previewBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      )
                    else
                      Image.file(
                        File(_imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(
                              width: 280,
                              height: 340,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 64,
                                  color: Colors.black38,
                                ),
                              ),
                            ),
                      ),
                    if (_previewBusy)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF14909A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Crop button
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6B7C85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _openCropScreen,
                icon: const Icon(
                  Icons.crop_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: 'Crop',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(Color textColor, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final filter = _filters[index];
              return _FilterCard(
                filter: filter,
                onTap: () => _onFilterSelected(filter.type),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required Color textColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: const Color(0xFF14909A),
              inactiveTrackColor: const Color(0xFFE6ECEF),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF14909A).withValues(alpha: 0.2),
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  Widget _buildFileNameInput(
    Color surfaceColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _fileNameController,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter file name',
                hintStyle: TextStyle(color: mutedColor, fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Add Page Button
            Expanded(
              child: OutlinedButton(
                onPressed: _onAddPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF14909A),
                  side: const BorderSide(color: Color(0xFF14909A), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Add Page',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Export Button
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _onExportPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14909A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Export PDF',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption {
  _FilterOption({
    required this.type,
    required this.label,
    required this.color,
    required this.iconColor,
    this.isSelected = false,
  });

  final DocFilter type;
  final String label;
  final Color color;
  final Color iconColor;
  bool isSelected;
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.filter, required this.onTap});

  final _FilterOption filter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 96,
            decoration: BoxDecoration(
              color: filter.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: filter.isSelected
                    ? const Color(0xFF14909A)
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Container(
                          height: 3,
                          width: index % 2 == 0 ? 24 : 18,
                          decoration: BoxDecoration(
                            color: filter.iconColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filter.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: filter.isSelected ? FontWeight.w600 : FontWeight.w500,
              color: filter.isSelected
                  ? const Color(0xFF14909A)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
