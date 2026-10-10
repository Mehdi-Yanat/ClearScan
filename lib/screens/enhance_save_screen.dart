import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class EnhanceSaveScreen extends StatefulWidget {
  const EnhanceSaveScreen({
    super.key,
    required this.imagePath,
    this.initialFileName = 'Scanned_Document',
    this.onSave,
    this.onAddPage,
  });

  final String imagePath;
  final String initialFileName;
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

enum _FilterType { original, magic, bw, gray, vivid }

class _EnhanceSaveScreenState extends State<EnhanceSaveScreen> {
  double _brightness = 0.5;
  double _contrast = 0.5;
  final TextEditingController _fileNameController = TextEditingController();
  String _selectedFormat = 'JPG';
  bool _saving = false;

  final List<_FilterOption> _filters = [
    _FilterOption(
      type: _FilterType.original,
      label: 'Original',
      color: Colors.white,
      iconColor: const Color(0xFF9AA8B0),
    ),
    _FilterOption(
      type: _FilterType.magic,
      label: 'Magic',
      color: const Color(0xFFFFF3D6),
      iconColor: const Color(0xFF14909A),
      isSelected: true,
    ),
    _FilterOption(
      type: _FilterType.bw,
      label: 'B&W',
      color: const Color(0xFFE8E8E8),
      iconColor: const Color(0xFF6B7C85),
    ),
    _FilterOption(
      type: _FilterType.gray,
      label: 'Gray',
      color: const Color(0xFFD1D1D1),
      iconColor: const Color(0xFF6B7C85),
    ),
    _FilterOption(
      type: _FilterType.vivid,
      label: 'Vivid',
      color: const Color(0xFFD4F1F3),
      iconColor: const Color(0xFF14909A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fileNameController.text = widget.initialFileName;
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  void _onFilterSelected(_FilterType type) {
    setState(() {
      for (var filter in _filters) {
        filter.isSelected = filter.type == type;
      }
    });
  }

  _EnhancementValues get _enhancementValues => _EnhancementValues(
    filter: _filters.firstWhere((filter) => filter.isSelected).type.index,
    brightness: _brightness,
    contrast: _contrast,
  );

  Future<void> _onSave() async {
    if (_saving) return;
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) {
      _showSnackBar('Please enter a file name');
      return;
    }

    if (widget.onSave != null) {
      setState(() => _saving = true);
      try {
        final sourceBytes = await File(widget.imagePath).readAsBytes();
        final enhancedBytes = await compute(
          _applyEnhancements,
          _EnhancementJob(bytes: sourceBytes, values: _enhancementValues),
        );
        await widget.onSave!(enhancedBytes, fileName, _selectedFormat);
        if (mounted) Navigator.of(context).pop(true);
      } on Exception catch (error) {
        _showSnackBar('Could not save the document: $error');
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    } else {
      _showSnackBar('Saving $fileName.$_selectedFormat...');
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                        onChanged: (v) => setState(() => _brightness = v),
                        textColor: textColor,
                      ),

                      const SizedBox(height: 24),

                      // Contrast Slider
                      _buildSliderRow(
                        label: 'Contrast',
                        value: _contrast,
                        onChanged: (v) => setState(() => _contrast = v),
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
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(
                    _enhancementColorMatrix(_enhancementValues),
                  ),
                  child: Image.file(
                    File(widget.imagePath),
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
                onPressed: () {
                  // TODO: Implement crop functionality
                },
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
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            initialValue: _selectedFormat,
            onSelected: (format) => setState(() => _selectedFormat = format),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'JPG', child: Text('JPG')),
              PopupMenuItem(value: 'PDF', child: Text('PDF')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F3F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedFormat,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14909A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF14909A),
                    size: 20,
                  ),
                ],
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
            // Save Button
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _onSave,
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
                        'Save $_selectedFormat',
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

class _EnhancementValues {
  const _EnhancementValues({
    required this.filter,
    required this.brightness,
    required this.contrast,
  });

  final int filter;
  final double brightness;
  final double contrast;
}

class _EnhancementJob {
  const _EnhancementJob({required this.bytes, required this.values});

  final Uint8List bytes;
  final _EnhancementValues values;
}

List<double> _enhancementColorMatrix(_EnhancementValues values) {
  var base = <double>[1, 0, 0, 0, 1, 0, 0, 0, 1];
  var presetContrast = 1.0;
  var presetBrightness = 0.0;
  switch (values.filter) {
    case 1:
      presetContrast = 1.12;
      presetBrightness = 10;
    case 2:
      base = const [
        0.299,
        0.587,
        0.114,
        0.299,
        0.587,
        0.114,
        0.299,
        0.587,
        0.114,
      ];
      presetContrast = 1.75;
    case 3:
      base = const [
        0.299,
        0.587,
        0.114,
        0.299,
        0.587,
        0.114,
        0.299,
        0.587,
        0.114,
      ];
    case 4:
      const saturation = 1.35;
      const red = 0.299 * (1 - saturation);
      const green = 0.587 * (1 - saturation);
      const blue = 0.114 * (1 - saturation);
      base = const [
        red + saturation,
        green,
        blue,
        red,
        green + saturation,
        blue,
        red,
        green,
        blue + saturation,
      ];
  }

  final contrast = values.contrast + 0.5;
  final brightness = (values.brightness - 0.5) * 100;
  final matrix = <double>[];
  for (var row = 0; row < 3; row++) {
    final offset = 128 * (1 - presetContrast) + presetBrightness;
    matrix.addAll([
      base[row * 3] * presetContrast * contrast,
      base[row * 3 + 1] * presetContrast * contrast,
      base[row * 3 + 2] * presetContrast * contrast,
      0,
      (offset - 128) * contrast + 128 + brightness,
    ]);
  }
  matrix.addAll([0, 0, 0, 1, 0]);
  return matrix;
}

Uint8List _applyEnhancements(_EnhancementJob job) {
  final source = img.decodeImage(job.bytes);
  if (source == null) throw const FormatException('Unsupported image');
  final matrix = _enhancementColorMatrix(job.values);
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final red = pixel.r.toDouble();
      final green = pixel.g.toDouble();
      final blue = pixel.b.toDouble();
      final outRed =
          matrix[0] * red + matrix[1] * green + matrix[2] * blue + matrix[4];
      final outGreen =
          matrix[5] * red + matrix[6] * green + matrix[7] * blue + matrix[9];
      final outBlue =
          matrix[10] * red +
          matrix[11] * green +
          matrix[12] * blue +
          matrix[14];
      source.setPixelRgb(
        x,
        y,
        outRed.round().clamp(0, 255),
        outGreen.round().clamp(0, 255),
        outBlue.round().clamp(0, 255),
      );
    }
  }
  return Uint8List.fromList(img.encodeJpg(source, quality: 94));
}

class _FilterOption {
  _FilterOption({
    required this.type,
    required this.label,
    required this.color,
    required this.iconColor,
    this.isSelected = false,
  });

  final _FilterType type;
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
