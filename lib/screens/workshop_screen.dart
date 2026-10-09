import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import 'scanner_screen.dart';

class WorkshopScreen extends StatefulWidget {
  const WorkshopScreen({super.key});

  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
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
        bottomNavigationBar: AppBottomBar(
          selectedIndex: 2,
          onScan: _openScanner,
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              // Title
              Text(
                'Workshop',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 32),

              // Convert Section
              _buildSectionTitle('Convert', textColor),
              const SizedBox(height: 16),
              _buildConvertGrid(),
              const SizedBox(height: 32),

              // Edit PDF Section
              _buildSectionTitle('Edit PDF', textColor),
              const SizedBox(height: 16),
              _buildEditPdfGrid(),
              const SizedBox(height: 32),

              // More Tools Section
              _buildSectionTitle('More Tools', textColor),
              const SizedBox(height: 16),
              _buildMoreToolsList(mutedColor),
            ],
          ),
        ),
      ),
    );
  }

  void _openScanner() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ScannerScreen()));
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }

  // ───────────────────────────── Convert Section ─────────────────────────────

  Widget _buildConvertGrid() {
    final tools = [
      _ConvertTool(
        icon: Icons.picture_as_pdf_rounded,
        label: 'Image to PDF',
        backgroundColor: const Color(0xFFFFE5E5),
        iconColor: const Color(0xFFE5484D),
      ),
      _ConvertTool(
        icon: Icons.image_rounded,
        label: 'PDF to Image',
        backgroundColor: const Color(0xFFE5F6EC),
        iconColor: const Color(0xFF2FB67C),
      ),
      _ConvertTool(
        icon: Icons.description_rounded,
        label: 'PDF to Word',
        backgroundColor: const Color(0xFFE5EDFF),
        iconColor: const Color(0xFF4A7dff),
      ),
      _ConvertTool(
        icon: Icons.table_chart_rounded,
        label: 'PDF to Excel',
        backgroundColor: const Color(0xFFE5F6EC),
        iconColor: const Color(0xFF2FB67C),
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < tools.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _ConvertToolCard(tool: tools[i])),
        ],
      ],
    );
  }

  // ───────────────────────────── Edit PDF Section ─────────────────────────────

  Widget _buildEditPdfGrid() {
    final tools = [
      _EditTool(icon: Icons.merge_type_rounded, label: 'Merge PDF'),
      _EditTool(icon: Icons.call_split_rounded, label: 'Split PDF'),
      _EditTool(icon: Icons.compress_rounded, label: 'Compress PDF'),
      _EditTool(icon: Icons.rotate_right_rounded, label: 'Rotate PDF'),
      _EditTool(icon: Icons.delete_outline_rounded, label: 'Delete Pages'),
      _EditTool(icon: Icons.swap_vert_rounded, label: 'Reorder Pages'),
      _EditTool(icon: Icons.file_upload_outlined, label: 'Extract Pages'),
      _EditTool(icon: Icons.lock_outline_rounded, label: 'Add Password'),
    ];

    return Column(
      children: [
        for (int row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 12),
          Row(
            children: [
              for (int col = 0; col < 4; col++) ...[
                if (col > 0) const SizedBox(width: 12),
                Expanded(child: _EditToolCard(tool: tools[row * 4 + col])),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // ───────────────────────────── More Tools Section ─────────────────────────────

  Widget _buildMoreToolsList(Color mutedColor) {
    final tools = [
      _MoreTool(
        icon: Icons.edit_rounded,
        title: 'Sign Document',
        subtitle: 'Add signature to your documents',
      ),
      _MoreTool(
        icon: Icons.water_drop_outlined,
        title: 'Watermark',
        subtitle: 'Add watermark to your documents',
      ),
      _MoreTool(
        icon: Icons.document_scanner_outlined,
        title: 'OCR',
        subtitle: 'Extract text from images',
      ),
      _MoreTool(
        icon: Icons.qr_code_rounded,
        title: 'QR Code Generator',
        subtitle: 'Create your own QR codes',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < tools.length; i++) ...[
            _MoreToolRow(tool: tools[i]),
            if (i < tools.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 68,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── Models ─────────────────────────────

class _ConvertTool {
  _ConvertTool({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
}

class _EditTool {
  _EditTool({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _MoreTool {
  _MoreTool({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;
}

// ───────────────────────────── Widgets ─────────────────────────────

class _ConvertToolCard extends StatelessWidget {
  const _ConvertToolCard({required this.tool});

  final _ConvertTool tool;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to specific tool
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 108,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tool.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tool.icon, color: tool.iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              tool.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditToolCard extends StatelessWidget {
  const _EditToolCard({required this.tool});

  final _EditTool tool;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to specific tool
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 108,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tool.icon, color: const Color(0xFF14909A), size: 28),
            const SizedBox(height: 12),
            Text(
              tool.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreToolRow extends StatelessWidget {
  const _MoreToolRow({required this.tool});

  final _MoreTool tool;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to specific tool
      },
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(tool.icon, color: const Color(0xFF14909A), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
