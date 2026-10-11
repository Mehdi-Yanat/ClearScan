import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import 'documents_screen.dart';
import 'pdf_edit_screen.dart';
import 'pdf_to_excel_screen.dart';
import 'pdf_to_image_screen.dart';
import 'pdf_to_word_screen.dart';
import 'ocr_screen.dart';
import 'qr_generator_screen.dart';
import '../services/pdf_editor.dart';
import 'scanner_screen.dart';
import 'sign_document_screen.dart';
import 'watermark_screen.dart';

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

  void _openPdfToImage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PdfToImageScreen()));
  }

  void _openPdfToWord() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const PdfToWordScreen()));
  }

  void _openPdfToExcel() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PdfToExcelScreen()));
  }

  void _openMergePdf() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DocumentsScreen(startMergeSelection: true),
      ),
    );
  }

  void _openPdfEdit(PdfEditOperation operation) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfEditScreen(operation: operation),
      ),
    );
  }

  void _openSignDocument() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SignDocumentScreen()));
  }

  void _openWatermark() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const WatermarkScreen()));
  }

  void _openOcr() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const OcrScreen()));
  }

  void _openQrGenerator() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const QrGeneratorScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    final strings = AppLocalizations.of(context)!;

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
                strings.workshopTitle,
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
              _SectionTitle(strings.workshopEditPdf),
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
          Expanded(
            child: _ConvertToolCard(
              tool: tools[i],
              onTap: switch (i) {
                1 => _openPdfToImage,
                2 => _openPdfToWord,
                3 => _openPdfToExcel,
                _ => null,
              },
            ),
          ),
        ],
      ],
    );
  }

  // ───────────────────────────── Edit PDF Section ─────────────────────────────

  Widget _buildEditPdfGrid() {
    final strings = AppLocalizations.of(context)!;
    final tools = [
      _EditTool(
        icon: Icons.merge_type_rounded,
        label: strings.toolMergePdf,
        onTap: _openMergePdf,
      ),
      _EditTool(
        icon: Icons.call_split_rounded,
        label: strings.toolSplitPdf,
        onTap: () => _openPdfEdit(PdfEditOperation.split),
      ),
      _EditTool(
        icon: Icons.compress_rounded,
        label: strings.toolCompressPdf,
        onTap: () => _openPdfEdit(PdfEditOperation.compress),
      ),
      _EditTool(
        icon: Icons.rotate_right_rounded,
        label: strings.toolRotatePdf,
        onTap: () => _openPdfEdit(PdfEditOperation.rotate),
      ),
      _EditTool(
        icon: Icons.delete_outline_rounded,
        label: strings.toolDeletePages,
        onTap: () => _openPdfEdit(PdfEditOperation.deletePages),
      ),
      _EditTool(
        icon: Icons.swap_vert_rounded,
        label: strings.toolReorderPages,
        onTap: () => _openPdfEdit(PdfEditOperation.reorderPages),
      ),
      _EditTool(
        icon: Icons.file_upload_outlined,
        label: strings.toolExtractPages,
        onTap: () => _openPdfEdit(PdfEditOperation.extractPages),
      ),
      _EditTool(
        icon: Icons.lock_outline_rounded,
        label: strings.toolAddPassword,
        onTap: () => _openPdfEdit(PdfEditOperation.addPassword),
      ),
    ];

    return Column(
      children: [
        for (var row = 0; row < (tools.length / 4).ceil(); row++) ...[
          if (row > 0) const SizedBox(height: 12),
          Row(
            children: [
              for (var col = 0; col < 4; col++) ...[
                if (col > 0) const SizedBox(width: 12),
                Expanded(
                  child: row * 4 + col < tools.length
                      ? _EditToolCard(tool: tools[row * 4 + col])
                      : const SizedBox(height: 108),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // ───────────────────────────── More Tools Section ─────────────────────────────

  Widget _buildMoreToolsList() {
    final strings = AppLocalizations.of(context)!;
    final tools = [
      _MoreTool(
        icon: Icons.edit_rounded,
        title: strings.toolSign,
        subtitle: strings.toolSignDesc,
        onTap: _openSignDocument,
      ),
      _MoreTool(
        icon: Icons.water_drop_outlined,
        title: strings.toolWatermark,
        subtitle: strings.toolWatermarkDesc,
        onTap: _openWatermark,
      ),
      _MoreTool(
        icon: Icons.document_scanner_outlined,
        title: strings.toolOcr,
        subtitle: strings.toolOcrDesc,
        onTap: _openOcr,
      ),
      _MoreTool(
        icon: Icons.qr_code_rounded,
        title: strings.toolQrGenerator,
        subtitle: strings.toolQrGeneratorDesc,
        onTap: _openQrGenerator,
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
  const _EditTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _MoreTool {
  const _MoreTool({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
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
  const _ToolCardShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

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
        onTap: onTap,
        child: SizedBox(height: 108, child: child),
      ),
    );
  }
}

class _ConvertToolCard extends StatelessWidget {
  const _ConvertToolCard({required this.tool, required this.onTap});

  final _ConvertTool tool;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ToolCardShell(
      onTap: onTap,
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
            // Cards are only ~60-70dp wide with four per row, so labels wrap
            // to two lines; cap it so a large system font can't overflow.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
      onTap: tool.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tool.icon, color: AppColors.primary(context), size: 28),
          const SizedBox(height: 12),
          Text(
            tool.label,
            textAlign: TextAlign.center,
            // Cards are only ~60-70dp wide with four per row, so labels wrap
            // to two lines; cap it so a large system font can't overflow.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
      onTap: tool.onTap,
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
