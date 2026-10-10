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
  void _openScanner() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ScannerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        // The bottom bar is painted with the surface color.
        systemNavigationBarColor: AppColors.surface(context),
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        bottomNavigationBar: AppBottomBar(
          selectedIndex: 2,
          onScan: _openScanner,
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                'Workshop',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink(context),
                ),
              ),
              const SizedBox(height: 32),
              const _SectionTitle('Convert'),
              const SizedBox(height: 16),
              _buildConvertGrid(),
              const SizedBox(height: 32),
              const _SectionTitle('Edit PDF'),
              const SizedBox(height: 16),
              _buildEditPdfGrid(),
              const SizedBox(height: 32),
              const _SectionTitle('More Tools'),
              const SizedBox(height: 16),
              _buildMoreToolsList(),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── Convert Section ─────────────────────────────

  Widget _buildConvertGrid() {
    const tools = [
      _ConvertTool(
        icon: Icons.picture_as_pdf_rounded,
        label: 'Image to PDF',
        accent: Color(0xFFE5484D),
      ),
      _ConvertTool(
        icon: Icons.image_rounded,
        label: 'PDF to Image',
        accent: Color(0xFF2FB67C),
      ),
      _ConvertTool(
        icon: Icons.description_rounded,
        label: 'PDF to Word',
        accent: Color(0xFF4A7DFF),
      ),
      _ConvertTool(
        icon: Icons.table_chart_rounded,
        label: 'PDF to Excel',
        accent: Color(0xFF2FB67C),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tools.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _ConvertToolCard(tool: tools[i])),
        ],
      ],
    );
  }

  // ───────────────────────────── Edit PDF Section ─────────────────────────────

  Widget _buildEditPdfGrid() {
    const tools = [
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
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 12),
          Row(
            children: [
              for (var col = 0; col < 4; col++) ...[
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

  Widget _buildMoreToolsList() {
    const tools = [
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

    // Material (not a decorated Container) so the row ripples are visible.
    return Material(
      color: AppColors.surface(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < tools.length; i++) ...[
            _MoreToolRow(tool: tools[i]),
            if (i < tools.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 60,
                color: AppColors.border(context),
              ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── Models ─────────────────────────────

class _ConvertTool {
  const _ConvertTool({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;
}

class _EditTool {
  const _EditTool({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _MoreTool {
  const _MoreTool({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

// ───────────────────────────── Widgets ─────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink(context),
      ),
    );
  }
}

/// Rounded surface card with a visible ripple (Material + InkWell).
class _ToolCardShell extends StatelessWidget {
  const _ToolCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to specific tool
        },
        child: SizedBox(height: 108, child: child),
      ),
    );
  }
}

class _ConvertToolCard extends StatelessWidget {
  const _ConvertToolCard({required this.tool});

  final _ConvertTool tool;

  @override
  Widget build(BuildContext context) {
    return _ToolCardShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              // Translucent tint of the accent: soft pastel in light mode and
              // a subtle glow in dark mode (the old fixed pastels were
              // blinding on the dark surface).
              color: tool.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tool.icon, color: tool.accent, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            tool.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.ink(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditToolCard extends StatelessWidget {
  const _EditToolCard({required this.tool});

  final _EditTool tool;

  @override
  Widget build(BuildContext context) {
    return _ToolCardShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tool.icon, color: AppColors.primary(context), size: 28),
          const SizedBox(height: 12),
          Text(
            tool.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.ink(context),
            ),
          ),
        ],
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
              Icon(tool.icon, color: AppColors.primary(context), size: 24),
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
                        color: AppColors.ink(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint(context),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
