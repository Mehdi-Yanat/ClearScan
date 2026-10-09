import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class EnhanceSaveScreen extends StatefulWidget {
  const EnhanceSaveScreen({
    super.key,
    required this.imagePath,
    this.onSave,
    this.onAddPage,
  });

  final String imagePath;
  final void Function(String filePath, String fileName, String format)? onSave;
  final VoidCallback? onAddPage;

  @override
  State<EnhanceSaveScreen> createState() => _EnhanceSaveScreenState();
}

enum _FilterType { original, magic, bw, gray, vivid }

class _EnhanceSaveScreenState extends State<EnhanceSaveScreen> {
  _FilterType _selectedFilter = _FilterType.magic;
  double _brightness = 0.5;
  double _contrast = 0.5;
  final TextEditingController _fileNameController = TextEditingController(
    text: 'Invoice_2387',
  );
  final String _selectedFormat = 'PDF';

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
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  void _onFilterSelected(_FilterType type) {
    setState(() {
      _selectedFilter = type;
      for (var filter in _filters) {
        filter.isSelected = filter.type == type;
      }
    });
  }

  void _onSave() {
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) {
      _showSnackBar('Please enter a file name');
      return;
    }

    if (widget.onSave != null) {
      widget.onSave!(widget.imagePath, fileName, _selectedFormat);
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
          // Document image placeholder
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
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Placeholder when image fails to load
                    return Container(
                      width: 280,
                      height: 340,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'INVOICE',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[600],
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Fake text lines
                          ...List.generate(
                            12,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 4,
                              ),
                              child: Container(
                                height: 8,
                                width: index % 3 == 0 ? 120 : 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
          Container(
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
            // Save PDF Button
            Expanded(
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14909A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
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
