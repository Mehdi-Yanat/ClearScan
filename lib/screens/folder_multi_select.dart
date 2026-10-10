import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_bottom_bar.dart';
import '../widgets/bottom_action_bar.dart';
import 'scanner_screen.dart';

class FolderMultiSelectScreen extends StatefulWidget {
  const FolderMultiSelectScreen({
    super.key,
    required this.folderName,
    this.itemCount = 0,
    this.totalSize = '0 MB',
  });

  final String folderName;
  final int itemCount;
  final String totalSize;

  @override
  State<FolderMultiSelectScreen> createState() =>
      _FolderMultiSelectScreenState();
}

class _FolderMultiSelectScreenState extends State<FolderMultiSelectScreen> {
  final Set<int> _selectedItems = {};
  bool _isMultiSelectMode = false;

  // Sample data - replace with your actual document data
  final List<_DocumentItem> _documents = [
    _DocumentItem(
      name: 'Contract Agreement',
      size: '2.4 MB',
      date: 'Oct 08',
      isSelected: true,
    ),
    _DocumentItem(name: 'NDA – Acme Corp', size: '1.2 MB', date: 'Oct 06'),
    _DocumentItem(name: 'Lease Agreement 2026', size: '3.8 MB', date: 'Oct 02'),
    _DocumentItem(
      name: 'Service Contract v2',
      size: '2.1 MB',
      date: 'Sep 28',
      isSelected: true,
    ),
    _DocumentItem(name: 'Employment Offer', size: '0.9 MB', date: 'Sep 21'),
    _DocumentItem(name: 'Vendor Agreement', size: '1.7 MB', date: 'Sep 14'),
  ];

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
          selectedIndex: 1,
          onScan: _openScanner,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // App Bar
              _buildAppBar(textColor, mutedColor),

              // Document List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    final isSelected =
                        _selectedItems.contains(index) || doc.isSelected;

                    return _DocumentListItem(
                      document: doc,
                      isSelected: isSelected,
                      isMultiSelectMode: _isMultiSelectMode,
                      onTap: () => _onDocumentTap(index),
                      onLongPress: () => _onDocumentLongPress(index),
                      onMorePressed: () => _onMorePressed(index),
                    );
                  },
                ),
              ),

              // Bottom Action Bar (visible in multi-select mode)
              if (_isMultiSelectMode || _selectedItems.isNotEmpty)
                _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color textColor, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          Row(
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
                  widget.folderName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              // View toggle button
              IconButton(
                onPressed: () {
                  // TODO: Toggle view mode (grid/list)
                },
                icon: Icon(Icons.grid_view_rounded, color: textColor, size: 24),
                tooltip: 'Change view',
              ),
              // More options button
              IconButton(
                onPressed: () {
                  // TODO: Show more options menu
                },
                icon: Icon(Icons.more_vert_rounded, color: textColor, size: 24),
                tooltip: 'More options',
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Subtitle row
          Padding(
            padding: const EdgeInsets.only(left: 52, right: 16),
            child: Row(
              children: [
                Text(
                  '${widget.itemCount} items • ${widget.totalSize}',
                  style: TextStyle(fontSize: 14, color: mutedColor),
                ),
                const Spacer(),
                // Sort/filter button
                TextButton.icon(
                  onPressed: () {
                    // TODO: Show sort options
                  },
                  icon: Icon(Icons.sort_rounded, color: mutedColor, size: 18),
                  label: Text(
                    'Date',
                    style: TextStyle(fontSize: 14, color: mutedColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return BottomActionBar(
      style: BottomActionBarStyle.floating,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      actions: [
        BottomActionBarItem(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: _onShare,
        ),
        BottomActionBarItem(
          icon: Icons.merge_type_rounded,
          label: 'Merge',
          onTap: _onMerge,
        ),
        BottomActionBarItem(
          icon: Icons.download_outlined,
          label: 'Export',
          onTap: _onExport,
        ),
        BottomActionBarItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          iconColor: const Color(0xFFFF6B6B),
          onTap: _onDelete,
        ),
      ],
    );
  }

  void _openScanner() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ScannerScreen()));
  }

  void _onDocumentTap(int index) {
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedItems.contains(index)) {
          _selectedItems.remove(index);
        } else {
          _selectedItems.add(index);
        }
        if (_selectedItems.isEmpty) {
          _isMultiSelectMode = false;
        }
      });
    } else {
      // TODO: Open document viewer
    }
  }

  void _onDocumentLongPress(int index) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedItems.add(index);
    });
  }

  void _onMorePressed(int index) {
    // TODO: Show document options menu
  }

  void _onShare() {
    // TODO: Implement share functionality
    _showSnackBar('Share ${_selectedItems.length} items');
  }

  void _onMerge() {
    // TODO: Implement merge functionality
    _showSnackBar('Merge ${_selectedItems.length} items');
  }

  void _onExport() {
    // TODO: Implement export functionality
    _showSnackBar('Export ${_selectedItems.length} items');
  }

  void _onDelete() {
    // TODO: Implement delete functionality
    _showSnackBar('Delete ${_selectedItems.length} items');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ───────────────────────────── Models ─────────────────────────────

class _DocumentItem {
  _DocumentItem({
    required this.name,
    required this.size,
    required this.date,
    this.isSelected = false,
  });

  final String name;
  final String size;
  final String date;
  final bool isSelected;
}

// ───────────────────────────── Widgets ─────────────────────────────

class _DocumentListItem extends StatelessWidget {
  const _DocumentListItem({
    required this.document,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onMorePressed,
  });

  final _DocumentItem document;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMorePressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF14909A).withValues(alpha: 0.1)
                : surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF14909A).withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.outline
                        .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Selection checkbox
              if (isMultiSelectMode || isSelected) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF14909A)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF14909A) : mutedColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
              ],

              // Document thumbnail
              Container(
                width: 48,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A3A42)
                      : const Color(0xFFF5F8FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.description_outlined,
                    color: mutedColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Document info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${document.size} • ${document.date}',
                      style: TextStyle(fontSize: 13, color: mutedColor),
                    ),
                  ],
                ),
              ),

              // More options
              IconButton(
                onPressed: onMorePressed,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: mutedColor,
                  size: 20,
                ),
                tooltip: 'More options',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
