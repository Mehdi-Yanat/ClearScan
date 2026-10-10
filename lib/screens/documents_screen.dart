import 'dart:io';

import 'package:clear_scan/widgets/app_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart' as loc;
import '../services/folder_repository.dart';
import '../services/notification_service.dart';
import '../services/recent_documents.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/folder_name_dialog.dart';
import '../widgets/share_sheet.dart';
import 'document_viewer_screen.dart';
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

enum _Filter { all, pdf, images, docs, favorites }

enum _Kind { pdf, image }

extension _FilterExtension on _Filter {
  String localizedLabel(BuildContext context) {
    final l = loc.AppLocalizations.of(context)!;
    return switch (this) {
      _Filter.all => l.documentsFilterAll,
      _Filter.pdf => l.documentsFilterPdf,
      _Filter.images => l.documentsFilterImages,
      _Filter.docs => l.documentsFilterDocs,
      _Filter.favorites => l.documentsFilterFavorites,
    };
  }
}

enum _Sort { date, name, size }

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

  List<DocumentFolder> _folders = [];
  bool _foldersLoading = true;
  String? _folderError;
  List<RecentDocument> _files = [];
  final Set<String> _favoritePaths = {};
  bool _filesLoading = true;
  String? _filesError;

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── derived data ──

  List<DocumentFolder> get _visibleFolders {
    if (_filter != _Filter.all) return const [];
    return _folders
        .where((f) => f.name.toLowerCase().contains(_query))
        .toList();
  }

  List<RecentDocument> get _visibleFiles {
    final list = _files.where((f) {
      final matchesQuery = f.name.toLowerCase().contains(_query);
      final matchesFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.pdf => f.type == 'PDF',
        _Filter.images => f.type == 'JPG' || f.type == 'PNG',
        _Filter.docs => false,
        _Filter.favorites => _favoritePaths.contains(f.path),
      };
      return matchesQuery && matchesFilter;
    }).toList();

    switch (_sort) {
      case _Sort.date:
        list.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      case _Sort.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _Sort.size:
        list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    }
    return list;
  }

  // ── actions ──

  Future<void> _openScanner() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ScannerScreen()),
    );
    if (mounted) await _loadFiles();
  }

  void _snack(String message, {SnackBarAction? action}) {
    showAppSnackBar(context, message, action: action);
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await loadDocumentFolders();
      if (!mounted) return;
      setState(() {
        _folders = folders;
        _foldersLoading = false;
        _folderError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _foldersLoading = false;
        _folderError = error.toString();
      });
    }
  }

  Future<void> _loadFiles() async {
    setState(() {
      _filesLoading = true;
      _filesError = null;
    });
    try {
      final files = await loadRecentDocuments(limit: null);
      if (!mounted) return;
      setState(() {
        _files = files;
        _filesLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _filesLoading = false;
        _filesError = error.toString();
      });
    }
  }

  Future<void> _deleteFolder(DocumentFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.AppLocalizations.of(dialogContext)!.delete),
        content: Text('Delete "${folder.name}" and its contents?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.AppLocalizations.of(dialogContext)!.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await deleteDocumentFolder(folder);
      await _loadFolders();
    } on FileSystemException catch (error) {
      if (mounted) _snack(error.message);
    }
  }

  Future<void> _createFolder() async {
    final name = await showFolderNameDialog(context);
    if (name == null || !mounted) return;
    try {
      await createDocumentFolder(name);
      await _loadFolders();
      await addNotification(
        AppNotificationType.folderCreated,
        detail: name.trim(),
      );
      if (mounted) _snack('"${name.trim()}" created');
    } on FileSystemException catch (error) {
      if (mounted) _snack(error.message);
    } on FormatException catch (error) {
      if (mounted) _snack(error.message);
    } on Exception catch (error) {
      if (mounted) {
        _snack('Folder created, but notification could not be saved: $error');
      }
    }
  }

  Future<void> _openDocument(RecentDocument document) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DocumentViewerScreen(document: document),
      ),
    );
    if (mounted) await _loadFiles();
  }

  Future<void> _shareDocument(RecentDocument document) async {
    final action = await showShareSheet(
      context,
      title: document.name,
      shareLabel: 'Share document',
      exportLabel: 'Save to device',
      fileType: document.type,
      fileSizeBytes: document.sizeBytes,
      previewImagePath: document.type == 'PDF' ? null : document.path,
      previewFilePath: document.path,
      loadPreviewPdfBytes: document.path.startsWith('content://')
          ? () => readRecentDocumentBytes(document)
          : null,
    );
    if (!mounted || action == null) return;
    try {
      if (action == ShareSheetAction.export) {
        await saveRecentDocumentToDevice(document);
        if (mounted) {
          await _loadFiles();
          _snack('Saved to device');
        }
      } else if (document.path.startsWith('content://')) {
        await shareRecentDocument(document);
      } else {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(document.path)], subject: document.name),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        _snack(
          action == ShareSheetAction.export
              ? 'Could not save to device: $error'
              : 'Could not share document: $error',
        );
      }
    }
  }

  Future<void> _deleteFile(RecentDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.AppLocalizations.of(dialogContext)!.delete),
        content: Text(
          loc.AppLocalizations.of(dialogContext)!
              .documentDeleteConfirmation(document.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.AppLocalizations.of(dialogContext)!.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await deleteRecentDocument(document);
      if (!mounted) return;
      setState(() => _favoritePaths.remove(document.path));
      await _loadFiles();
      if (mounted) {
        _snack(
          loc.AppLocalizations.of(context)!
              .documentDeleteSuccess(document.name),
        );
      }
    } on Exception catch (error) {
      if (mounted) _snack('Could not delete document: $error');
    }
  }

  Future<void> _renameFile(RecentDocument document) async {
    final extensionIndex = document.name.lastIndexOf('.');
    final extension = extensionIndex > 0
        ? document.name.substring(extensionIndex)
        : '';
    var name = extensionIndex > 0
        ? document.name.substring(0, extensionIndex)
        : document.name;
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.AppLocalizations.of(dialogContext)!.rename),
        content: TextFormField(
          initialValue: name,
          autofocus: true,
          onChanged: (value) => name = value,
          decoration: const InputDecoration(labelText: 'File name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(name.trim()),
            child: Text(loc.AppLocalizations.of(dialogContext)!.rename),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || !mounted) return;
    try {
      await renameRecentDocument(document, '$newName$extension');
      if (!mounted) return;
      await _loadFiles();
      if (mounted) _snack('Document renamed');
    } on Exception catch (error) {
      if (mounted) _snack('Could not rename document: $error');
    }
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
                  loc.AppLocalizations.of(sheetContext)!.documentsSortBy,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink(sheetContext),
                  ),
                ),
              ),
            ),
            for (final (value, label) in [
              (_Sort.date, loc.AppLocalizations.of(sheetContext)!.sortDate),
              (_Sort.name, loc.AppLocalizations.of(sheetContext)!.sortName),
              (_Sort.size, loc.AppLocalizations.of(sheetContext)!.sortSize),
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
    final action = await showModalBottomSheet<String>(
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
              label: loc.AppLocalizations.of(context)!.scanDocument,
              onTap: () {
                Navigator.of(sheetContext).pop('scan');
              },
            ),
            _AddTile(
              icon: Icons.create_new_folder_outlined,
              label: loc.AppLocalizations.of(context)!.newFolder,
              onTap: () {
                Navigator.of(sheetContext).pop('folder');
              },
            ),
            _AddTile(
              icon: Icons.folder_open_outlined,
              label: loc.AppLocalizations.of(context)!.importFile,
              onTap: () {
                Navigator.of(sheetContext).pop('import');
                // TODO: file picker import
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'scan') _openScanner();
    if (action == 'folder') await _createFolder();
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final folders = _visibleFolders;
    final files = _visibleFiles;
    final isEmpty =
        folders.isEmpty &&
        files.isEmpty &&
        !_foldersLoading &&
        _folderError == null &&
        !_filesLoading &&
        _filesError == null;
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
                          if (_foldersLoading)
                            const Center(child: CircularProgressIndicator()),
                          if (_folderError != null)
                            Text(
                              _folderError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          if (_filesLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          if (_filesError != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    _filesError!,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _loadFiles,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
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
                                    favorite: _favoritePaths.contains(
                                      file.path,
                                    ),
                                    onTap: () => _openDocument(file),
                                    onToggleFavorite: () => setState(
                                      () => _favoritePaths.contains(file.path)
                                          ? _favoritePaths.remove(file.path)
                                          : _favoritePaths.add(file.path),
                                    ),
                                    onDelete: () => _deleteFile(file),
                                    onShare: () => _shareDocument(file),
                                    onRename: () => _renameFile(file),
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
            loc.AppLocalizations.of(context)!.documentsTitle,
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
            tooltip: loc.AppLocalizations.of(context)!.searchTooltip,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.ink(context)),
            onSelected: (value) {
              if (value == 'new') onNewFolder();
              // TODO: 'select' → multi-select mode
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'select',
                child: Text(loc.AppLocalizations.of(context)!.selectOption),
              ),
              PopupMenuItem(
                value: 'new',
                child: Text(loc.AppLocalizations.of(context)!.newOption),
              ),
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
          hintText: loc.AppLocalizations.of(context)!.searchHint,
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                filter.localizedLabel(context),
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

  final DocumentFolder folder;
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
                    '${folder.itemCount} items',
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
    required this.favorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onShare,
    required this.onRename,
  });

  final RecentDocument file;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onRename;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final modified = DateFormat.yMMMd(locale).add_jm().format(file.modifiedAt);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        child: Row(
          children: [
            _Thumb(kind: file.type == 'PDF' ? _Kind.pdf : _Kind.image),
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
                    '${file.type}  •  ${_formatSize(file.sizeBytes)}  •  $modified',
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
              tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
              icon: Icon(
                favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 22,
                color: favorite
                    ? AppColors.warning
                    : AppColors.textHint(context),
              ),
            ),
            _MoreMenu(onDelete: onDelete, onShare: onShare, onRename: onRename),
          ],
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onDelete, this.onShare, this.onRename});

  final VoidCallback onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: AppColors.textMuted(context),
      ),
      onSelected: (value) {
        if (value == 'share') onShare?.call();
        if (value == 'rename') onRename?.call();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        if (onShare != null)
          PopupMenuItem(
            value: 'share',
            child: Text(loc.AppLocalizations.of(context)!.share),
          ),
        if (onRename != null)
          PopupMenuItem(
            value: 'rename',
            child: Text(loc.AppLocalizations.of(context)!.rename),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Text(loc.AppLocalizations.of(context)!.delete),
        ),
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
            loc.AppLocalizations.of(context)!.noDocumentsFound,
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
