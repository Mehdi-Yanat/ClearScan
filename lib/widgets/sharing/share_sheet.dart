import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

enum ShareSheetAction { share, export }

Future<ShareSheetAction?> showShareSheet(
  BuildContext context, {
  required String title,
  required String shareLabel,
  String? exportLabel,
  String? fileType,
  int? fileSizeBytes,
  int? pageCount,
  Uint8List? previewBytes,
  String? previewImagePath,
  String? previewFilePath,
  Future<Uint8List> Function()? loadPreviewPdfBytes,
}) {
  final colors = Theme.of(context).colorScheme;
  return showModalBottomSheet<ShareSheetAction>(
    context: context,
    backgroundColor: colors.surface,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => _ShareSheet(
      title: title,
      shareLabel: shareLabel,
      exportLabel: exportLabel,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      pageCount: pageCount,
      previewBytes: previewBytes,
      previewImagePath: previewImagePath,
      previewFilePath: previewFilePath,
      loadPreviewPdfBytes: loadPreviewPdfBytes,
    ),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.title,
    required this.shareLabel,
    required this.exportLabel,
    required this.fileType,
    required this.fileSizeBytes,
    required this.pageCount,
    required this.previewBytes,
    required this.previewImagePath,
    required this.previewFilePath,
    required this.loadPreviewPdfBytes,
  });

  final String title;
  final String shareLabel;
  final String? exportLabel;
  final String? fileType;
  final int? fileSizeBytes;
  final int? pageCount;
  final Uint8List? previewBytes;
  final String? previewImagePath;
  final String? previewFilePath;
  final Future<Uint8List> Function()? loadPreviewPdfBytes;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  Uint8List? _pdfBytes;
  bool _pdfLoadFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.fileType == 'PDF' &&
        widget.previewFilePath?.startsWith('content://') == true &&
        widget.loadPreviewPdfBytes != null) {
      _loadPdfPreview();
    }
  }

  Future<void> _loadPdfPreview() async {
    try {
      final bytes = await widget.loadPreviewPdfBytes!();
      if (mounted) setState(() => _pdfBytes = bytes);
    } on Exception catch (error) {
      debugPrint('Could not read PDF preview: $error');
      if (mounted) setState(() => _pdfLoadFailed = true);
    }
  }

  String get _fileDetails => [
    if (widget.fileType != null) widget.fileType,
    if (widget.pageCount != null)
      '${widget.pageCount} ${widget.pageCount == 1 ? 'page' : 'pages'}',
    if (widget.fileSizeBytes != null) _formatFileSize(widget.fileSizeBytes!),
  ].join(' • ');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final actions = <_ShareSheetOptionData>[
      _ShareSheetOptionData(
        label: widget.shareLabel,
        icon: Icons.share_outlined,
        action: ShareSheetAction.share,
      ),
      const _ShareSheetOptionData(label: 'Email', icon: Icons.email_outlined),
      const _ShareSheetOptionData(label: 'Copy link', icon: Icons.link_rounded),
      _ShareSheetOptionData(
        label: widget.exportLabel ?? 'Save to device',
        icon: Icons.file_download_outlined,
        action: widget.exportLabel == null ? null : ShareSheetAction.export,
      ),
      const _ShareSheetOptionData(label: 'Print', icon: Icons.print_outlined),
      const _ShareSheetOptionData(label: 'Cloud', icon: Icons.cloud_outlined),
      const _ShareSheetOptionData(
        label: 'As images',
        icon: Icons.image_outlined,
      ),
      const _ShareSheetOptionData(
        label: 'As text',
        icon: Icons.text_fields_rounded,
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _DocumentThumbnail(
                    previewBytes: widget.previewBytes,
                    imagePath: widget.previewImagePath,
                    pdfPath: widget.fileType == 'PDF'
                        ? widget.previewFilePath
                        : null,
                    pdfBytes: _pdfBytes,
                    pdfFailed: _pdfLoadFailed,
                    onPdfError: () {
                      if (mounted) setState(() => _pdfLoadFailed = true);
                    },
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_fileDetails.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _fileDetails,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Flexible(
                child: SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: actions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.78,
                        ),
                    itemBuilder: (context, index) {
                      final option = actions[index];
                      return _ActionGridItem(
                        option: option,
                        onTap: option.action == null
                            ? null
                            : () => Navigator.pop(context, option.action),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHighest,
                    foregroundColor: colors.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentThumbnail extends StatelessWidget {
  const _DocumentThumbnail({
    this.previewBytes,
    this.imagePath,
    this.pdfPath,
    this.pdfBytes,
    this.pdfFailed = false,
    this.onPdfError,
  });

  final Uint8List? previewBytes;
  final String? imagePath;
  final String? pdfPath;
  final Uint8List? pdfBytes;
  final bool pdfFailed;
  final VoidCallback? onPdfError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isContentUri = pdfPath?.startsWith('content://') ?? false;
    final Widget preview;
    if (previewBytes != null) {
      preview = Image.memory(
        previewBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colors),
      );
    } else if (imagePath != null) {
      preview = Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colors),
      );
    } else if (pdfPath != null && !pdfFailed) {
      preview = isContentUri && pdfBytes == null
          ? const Center(
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            )
          : IgnorePointer(
              child: PDFView(
                filePath: isContentUri ? null : pdfPath,
                pdfData: isContentUri ? pdfBytes : null,
                defaultPage: 0,
                enableSwipe: false,
                autoSpacing: false,
                pageFling: false,
                fitPolicy: FitPolicy.BOTH,
                onError: (_) => onPdfError?.call(),
              ),
            );
    } else {
      preview = _buildPlaceholder(colors);
    }

    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: preview,
    );
  }

  Widget _buildPlaceholder(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 30,
            height: 5,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          for (var index = 0; index < 4; index++)
            Container(
              width: index.isEven ? double.infinity : 34,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShareSheetOptionData {
  const _ShareSheetOptionData({
    required this.label,
    required this.icon,
    this.action,
  });

  final String label;
  final IconData icon;
  final ShareSheetAction? action;
}

class _ActionGridItem extends StatelessWidget {
  const _ActionGridItem({required this.option, required this.onTap});

  final _ShareSheetOptionData option;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(option.icon, color: colors.primary, size: 30),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                option.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: enabled ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
              if (!enabled)
                Text(
                  'Coming soon',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
