import 'package:clear_scan/widgets/app_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'scanner_screen.dart';

/// Text/icon color that stays readable on the primary color in each theme
/// (bright teal in dark mode needs dark text, deep teal in light mode needs white).
Color _onPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF0B1E26)
    : Colors.white;

/// Fill for the search field and filter button.
Color _fieldFill(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.surface(context)
    : const Color(0xFFEAEFF2);

// Thumbnails represent sheets of paper, so they stay white in both themes.
const _paperBorder = Color(0xFFE6ECEF);
const _paperPrimary = Color(0xFF14909A);

enum _Filter {
  all('All'),
  pdf('PDF'),
  images('Images'),
  docs('Docs'),
  favorites('Favorites');

  const _Filter(this.label);
  final String label;
}

enum _Sort { date, name, size }

enum _Kind { pdf, image, doc }

class _Folder {
  _Folder(this.name, this.items);
  String name;
  int items;
}

class _DocFile {
  _DocFile(
    this.name,
    this.kind,
    this.sizeKb,
    this.when, {
    this.favorite = false,
  });

  String name;
  final _Kind kind;
  final int sizeKb;
  final String when;
  bool favorite;

  String get typeLabel => switch (kind) {
    _Kind.pdf => 'PDF',
    _Kind.image => 'JPG',
    _Kind.doc => 'DOCX',
  };

  String get sizeLabel => sizeKb >= 1024
      ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
      : '$sizeKb KB';
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.date;
  String _query = '';

  // Replace with data from your document repository.
  final List<_Folder> _folders = [
    _Folder('ID Cards', 12),
    _Folder('Passports', 8),
    _Folder('Contracts', 15),
    _Folder('Receipts', 27),
    _Folder('Notes', 34),
  ];

  final List<_DocFile> _files = [
    _DocFile('Contract Agreement', _Kind.pdf, 2458, '10:30 AM', favorite: true),
    _DocFile('Passport – John Doe', _Kind.pdf, 1126, 'Yesterday'),
    _DocFile('Invoice #INV-2387', _Kind.pdf, 1843, '2 days ago'),
    _DocFile('Meeting Notes', _Kind.doc, 320, '3 days ago'),
    _DocFile(
      'Receipt – Hardware Store',
      _Kind.image,
      860,
      '4 days ago',
      favorite: true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── derived data ──

  List<_Folder> get _visibleFolders {
    if (_filter != _Filter.all) return const [];
    return _folders
        .where((f) => f.name.toLowerCase().contains(_query))
        .toList();
  }

  List<_DocFile> get _visibleFiles {
    final list = _files.where((f) {
      final matchesQuery = f.name.toLowerCase().contains(_query);
      final matchesFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.pdf => f.kind == _Kind.pdf,
        _Filter.images => f.kind == _Kind.image,
        _Filter.docs => f.kind == _Kind.doc,
        _Filter.favorites => f.favorite,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    switch (_sort) {
      case _Sort.date:
        break; // sample data is already newest-first; sort by a real timestamp in production
      case _Sort.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _Sort.size:
        list.sort((a, b) => b.sizeKb.compareTo(a.sizeKb));
    }
    return list;
  }

  // ── actions ──

  void _openScanner() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ScannerScreen()));
  }

  void _snack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  void _deleteFolder(_Folder folder) {
    final index = _folders.indexOf(folder);
    setState(() => _folders.remove(folder));
    _snack(
      '"${folder.name}" deleted',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => setState(() => _folders.insert(index, folder)),
      ),
    );
  }

  void _deleteFile(_DocFile file) {
    final index = _files.indexOf(file);
    setState(() => _files.remove(file));
    _snack(
      '"${file.name}" deleted',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => setState(() => _files.insert(index, file)),
      ),
    );
  }

  Future<void> _showSortSheet() async {
    final picked = await showModalBottomSheet<_Sort>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sort by',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink(sheetContext),
                  ),
                ),
              ),
            ),
            for (final (value, label) in const [
              (_Sort.date, 'Date'),
              (_Sort.name, 'Name'),
              (_Sort.size, 'Size'),
            ])
              ListTile(
                title: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.ink(sheetContext),
                  ),
                ),
                trailing: _sort == value
                    ? Icon(
                        Icons.check_rounded,
                        color: AppColors.primary(sheetContext),
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  Future<void> _showAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const _SheetHandle(),
            const SizedBox(height: 8),
            _AddTile(
              icon: Icons.photo_camera_outlined,
              label: 'Scan document',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openScanner();
              },
            ),
            _AddTile(
              icon: Icons.create_new_folder_outlined,
              label: 'New folder',
              onTap: () {
                Navigator.of(sheetContext).pop();
                // TODO: ask for a folder name, then add it to your repository.
              },
            ),
            _AddTile(
              icon: Icons.folder_open_outlined,
              label: 'Import file',
              onTap: () {
                Navigator.of(sheetContext).pop();
                // TODO: file picker import
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final folders = _visibleFolders;
    final files = _visibleFiles;
    final isEmpty = folders.isEmpty && files.isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: AppColors.surface(context),
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        floatingActionButton: FloatingActionButton(
          heroTag: 'documents_add',
          onPressed: _showAddSheet,
          backgroundColor: AppColors.primary(context),
          foregroundColor: _onPrimary(context),
          elevation: 3,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
        bottomNavigationBar: AppBottomBar(
          selectedIndex: 1,
          onScan: _openScanner,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                onSearch: _searchFocus.requestFocus,
                onNewFolder: _showAddSheet,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _SearchField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        onChanged: (v) =>
                            setState(() => _query = v.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _FilterButton(onTap: _showSortSheet),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FilterChips(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: isEmpty
                    ? const _EmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
                        children: [
                          if (folders.isNotEmpty)
                            _Card(
                              children: [
                                for (final folder in folders)
                                  _FolderRow(
                                    folder: folder,
                                    onTap: () {
                                      // TODO: open folder contents
                                    },
                                    onDelete: () => _deleteFolder(folder),
                                  ),
                              ],
                            ),
                          if (folders.isNotEmpty && files.isNotEmpty)
                            const SizedBox(height: 14),
                          if (files.isNotEmpty)
                            _Card(
                              children: [
                                for (final file in files)
                                  _FileRow(
                                    file: file,
                                    onTap: () {
                                      // TODO: open document viewer
                                    },
                                    onToggleFavorite: () => setState(
                                      () => file.favorite = !file.favorite,
                                    ),
                                    onDelete: () => _deleteFile(file),
                                  ),
                              ],
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Header & controls ─────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onSearch, required this.onNewFolder});

  final VoidCallback onSearch;
  final VoidCallback onNewFolder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
      child: Row(
        children: [
          Text(
            'Documents',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink(context),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onSearch,
            icon: Icon(
              Icons.search_rounded,
              size: 26,
              color: AppColors.ink(context),
            ),
            tooltip: 'Search',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.ink(context)),
            onSelected: (value) {
              if (value == 'new') onNewFolder();
              // TODO: 'select' → multi-select mode
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'select', child: Text('Select')),
              PopupMenuItem(value: 'new', child: Text('New…')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.textMuted(context);

    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.primary(context),
        style: TextStyle(fontSize: 13.5, color: AppColors.ink(context)),
        decoration: InputDecoration(
          hintText: 'Search documents',
          hintStyle: TextStyle(fontSize: 13.5, color: muted),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: muted),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: muted),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
          filled: true,
          fillColor: _fieldFill(context),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _fieldFill(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 46,
          child: Icon(
            Icons.filter_alt_outlined,
            size: 21,
            color: AppColors.ink(context),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final _Filter selected;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);

    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _Filter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = _Filter.values[i];
          final active = filter == selected;
          return GestureDetector(
            onTap: () => onChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? primary : AppColors.surface(context),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: active ? primary : AppColors.border(context),
                ),
              ),
              child: Text(
                filter.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                  color: active ? _onPrimary(context) : AppColors.ink(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────────── Lists ─────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Material (not Container) so the InkWell ripples on the rows are visible.
    return Material(
      color: AppColors.surface(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 72,
                color: AppColors.border(context),
              ),
          ],
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.folder,
    required this.onTap,
    required this.onDelete,
  });

  final _Folder folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 4, 10),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Icon(
                Icons.folder_rounded,
                size: 32,
                color: AppColors.primary(context),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${folder.items} items',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            _MoreMenu(onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.file,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  final _DocFile file;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        child: Row(
          children: [
            _Thumb(kind: file.kind),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${file.typeLabel}  •  ${file.sizeLabel}  •  ${file.when}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onToggleFavorite,
              visualDensity: VisualDensity.compact,
              tooltip: file.favorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              icon: Icon(
                file.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 22,
                color: file.favorite
                    ? AppColors.warning
                    : AppColors.textHint(context),
              ),
            ),
            _MoreMenu(onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: AppColors.textMuted(context),
      ),
      onSelected: (value) {
        if (value == 'delete') onDelete();
        // TODO: 'share', 'rename'
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'share', child: Text('Share')),
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.kind});

  final _Kind kind;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: _paperBorder),
    );

    if (kind == _Kind.image) {
      return Container(
        width: 40,
        height: 50,
        decoration: decoration,
        child: const Icon(Icons.image_outlined, size: 22, color: _paperPrimary),
      );
    }

    return Container(
      width: 40,
      height: 50,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFB9C4CA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 5),
          for (var i = 0; i < 4; i++) ...[
            FractionallySizedBox(
              widthFactor: i == 2 ? 0.7 : 1,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DDE1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 48,
            color: AppColors.textHint(context),
          ),
          const SizedBox(height: 12),
          Text(
            'No documents found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Sheets ─────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border(context),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          // Translucent tint stays visible on the surface in both themes
          // (primaryLight is nearly invisible on the dark surface).
          color: primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: primary, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.ink(context),
        ),
      ),
    );
  }
}
