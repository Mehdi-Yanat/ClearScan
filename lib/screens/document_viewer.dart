import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/bottom_action_bar.dart';

class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({
    super.key,
    required this.documentName,
    this.totalPages = 1,
    this.onShare,
    this.onSign,
    this.onOcr,
    this.onEdit,
    this.onDelete,
  });

  final String documentName;
  final int totalPages;
  final VoidCallback? onShare;
  final VoidCallback? onSign;
  final VoidCallback? onOcr;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  int _currentPage = 1;
  bool _isFavorite = false;
  final ScrollController _thumbnailScrollController = ScrollController();

  @override
  void dispose() {
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  void _onPageSelected(int page) {
    setState(() {
      _currentPage = page;
    });
    // Scroll thumbnail to center
    _scrollThumbnailToCenter(page);
  }

  void _scrollThumbnailToCenter(int page) {
    const itemWidth = 88.0; // thumbnail width + margin
    final offset =
        (page - 1) * itemWidth -
        (MediaQuery.of(context).size.width / 2) +
        (itemWidth / 2);
    _thumbnailScrollController.animateTo(
      offset.clamp(0.0, _thumbnailScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

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
        body: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(textColor),

              // Document Preview
              Expanded(child: _buildDocumentPreview()),

              // Page Indicator
              _buildPageIndicator(),

              const SizedBox(height: 16),

              // Page Thumbnails
              _buildPageThumbnails(),

              const SizedBox(height: 24),

              // Bottom Action Bar
              _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color textColor) {
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
          Expanded(
            child: Text(
              widget.documentName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Favorite button
          IconButton(
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? const Color(0xFFF5A524) : textColor,
              size: 26,
            ),
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
          // More options
          IconButton(
            onPressed: () {
              _showMoreOptions();
            },
            icon: Icon(Icons.more_vert_rounded, color: textColor, size: 24),
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A3A42) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(child: _buildPageContent()),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    // Placeholder content - replace with actual PDF/image viewer
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Title
          Text(
            'CONTRACT AGREEMENT',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          // Fake content lines
          ...List.generate(
            20,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 8,
                width: index % 4 == 0 ? 200 : double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Signature row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Signature',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A3A42) : const Color(0xFF0F2A33),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$_currentPage / ${widget.totalPages}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPageThumbnails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _thumbnailScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: widget.totalPages,
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          final isSelected = pageNum == _currentPage;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _onPageSelected(pageNum),
              child: Container(
                width: 72,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF14909A)
                        : Theme.of(context).colorScheme.outline
                              .withValues(alpha: 0.3),
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F2A33)
                              : const Color(0xFFF5F8FA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.description_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '$pageNum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? const Color(0xFF14909A)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return BottomActionBar(
      actions: [
        BottomActionBarItem(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: widget.onShare ?? () => _showSnackBar('Share'),
        ),
        BottomActionBarItem(
          icon: Icons.edit_outlined,
          label: 'Sign',
          onTap: widget.onSign ?? () => _showSnackBar('Sign'),
        ),
        BottomActionBarItem(
          icon: Icons.document_scanner_outlined,
          label: 'OCR',
          onTap: widget.onOcr ?? () => _showSnackBar('OCR'),
        ),
        BottomActionBarItem(
          icon: Icons.edit_rounded,
          label: 'Edit',
          onTap: widget.onEdit ?? () => _showSnackBar('Edit'),
        ),
        BottomActionBarItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          iconColor: const Color(0xFFE5484D),
          backgroundColor: const Color(0xFFFFE5E5),
          onTap: widget.onDelete ?? _showDeleteDialog,
        ),
      ],
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Download');
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('Print'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Print');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Document info'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Document info');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete document?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(
            fontSize: 13.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back after delete
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFE5484D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
