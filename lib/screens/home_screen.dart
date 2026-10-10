import 'dart:async';
import 'dart:io';

import 'package:clear_scan/screens/scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'crop_adjust_screen.dart';
import 'enhance_save_screen.dart';
import 'document_viewer_screen.dart';
import 'notifications_screen.dart';
import '../l10n/app_localizations.dart' as loc;
import '../services/document_storage.dart';
import '../services/folder_repository.dart';
import '../services/notification_service.dart';
import '../services/recent_documents.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/folder_name_dialog.dart';
import '../widgets/share_sheet.dart';

// Hero card stays dark navy in both themes, so its text/paper use fixed colors.
const _heroBackground = Color(0xFF0F2A33);
const _heroMutedText = Color(0xFFB7CDD2);

/// Text/icon color that stays readable on the primary color in each theme
/// (bright teal in dark mode needs dark text, deep teal in light mode needs white).
Color _onPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF0B1E26)
    : Colors.white;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<RecentDocument>> _recentDocumentsFuture;

  @override
  void initState() {
    super.initState();
    _recentDocumentsFuture = loadRecentDocuments();
    unawaited(
      loadNotifications().then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          if (mounted) _showNotificationError(error);
        },
      ),
    );
  }

  void _refreshRecentDocuments() {
    setState(() {
      _recentDocumentsFuture = loadRecentDocuments();
    });
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
        if (!mounted) return;
        _refreshRecentDocuments();
        _showFolderError('Saved to device');
      } else if (document.path.startsWith('content://')) {
        await shareRecentDocument(document);
      } else {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(document.path)], subject: document.name),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        _showFolderError(
          action == ShareSheetAction.export
              ? 'Could not save to device: $error'
              : 'Could not share document: $error',
        );
      }
    }
  }

  Future<void> _renameDocument(RecentDocument document) async {
    final localizations = loc.AppLocalizations.of(context)!;
    final extensionIndex = document.name.lastIndexOf('.');
    final extension = extensionIndex > 0
        ? document.name.substring(extensionIndex)
        : '';
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDocumentDialog(
        title: localizations.rename,
        initialName: extensionIndex > 0
            ? document.name.substring(0, extensionIndex)
            : document.name,
      ),
    );
    if (name == null || !mounted) return;

    try {
      await renameRecentDocument(document, '$name$extension');
      if (!mounted) return;
      _refreshRecentDocuments();
      _showFolderError(localizations.documentRenameSuccess('$name$extension'));
    } on Exception catch (error) {
      if (mounted) _showFolderError('Could not rename document: $error');
    }
  }

  Future<void> _deleteDocument(RecentDocument document) async {
    final localizations = loc.AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizations.delete),
        content: Text(localizations.documentDeleteConfirmation(document.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await deleteRecentDocument(document);
      if (!mounted) return;
      _refreshRecentDocuments();
      _showFolderError(localizations.documentDeleteSuccess(document.name));
    } on Exception catch (error) {
      if (mounted) _showFolderError('Could not delete document: $error');
    }
  }

  void _openScanner() {
    _openScannerWithMode(ScanMode.document);
  }

  void _openScannerWithMode(ScanMode mode) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ScannerScreen(initialMode: mode),
          ),
        )
        .then((_) {
          if (mounted) _refreshRecentDocuments();
        });
  }

  Future<void> _importImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;
      final result = await Navigator.of(context).push<CropResult>(
        MaterialPageRoute<CropResult>(
          builder: (_) => CropAdjustScreen(imagePath: image.path),
        ),
      );
      if (mounted) {
        if (result?.path == null) return;
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => EnhanceSaveScreen(
              imagePath: result!.path!,
              initialFileName:
                  'Imported_${image.name.replaceFirst(RegExp(r'\.[^.]+$'), '')}',
              onSave: (imageBytes, fileName, format) async {
                final String savedName;
                if (format.toUpperCase() == 'PDF') {
                  final saved = await saveEnhancedPdfToDevice(
                    imageBytes: imageBytes,
                    name: fileName,
                  );
                  savedName = saved.filename;
                } else {
                  final saved = await saveEnhancedDocument(
                    imageBytes: imageBytes,
                    name: fileName,
                    format: format,
                  );
                  savedName = saved.uri.pathSegments.last;
                }
                _refreshRecentDocuments();
                if (mounted) {
                  _showFolderError('Saved $savedName');
                }
                try {
                  await addNotification(
                    AppNotificationType.imageImported,
                    detail: savedName,
                  );
                } on Exception catch (error) {
                  if (mounted) _showNotificationError(error);
                }
              },
            ),
          ),
        );
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      final message =
          error.message ?? 'Could not select an image (${error.code}).';
      showAppSnackBar(context, message);
    } on Exception catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, 'Could not save the imported image: $error');
    }
  }

  Future<void> _createFolder() async {
    final name = await showFolderNameDialog(context);
    if (name == null || !mounted) return;

    try {
      await createDocumentFolder(name);
      if (!mounted) return;
      var savedNotification = true;
      try {
        await addNotification(
          AppNotificationType.folderCreated,
          detail: name.trim(),
        );
      } on Exception catch (error) {
        if (mounted) {
          _showNotificationError(error);
        }
        savedNotification = false;
      }
      if (!mounted) return;
      if (savedNotification) {
        showAppSnackBar(context, '"${name.trim()}" created');
      }
    } on FileSystemException catch (error) {
      if (!mounted) return;
      _showFolderError(error.message);
    } on FormatException catch (error) {
      if (!mounted) return;
      _showFolderError(error.message);
    }
  }

  void _showFolderError(String message) {
    showAppSnackBar(context, message);
  }

  void _showNotificationError(Object error) {
    showAppSnackBar(context, 'Could not save notification: $error');
  }

  Future<void> _showAddSheet() async {
    ModalRoute<dynamic>? addSheetRoute;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        addSheetRoute = ModalRoute.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const _AddSheetHandle(),
              const SizedBox(height: 8),
              _HomeAddTile(
                icon: Icons.photo_camera_outlined,
                label: loc.AppLocalizations.of(sheetContext)!.scanDocument,
                onTap: () => Navigator.of(sheetContext).pop('scan'),
              ),
              _HomeAddTile(
                icon: Icons.create_new_folder_outlined,
                label: loc.AppLocalizations.of(sheetContext)!.newFolder,
                onTap: () => Navigator.of(sheetContext).pop('folder'),
              ),
              _HomeAddTile(
                icon: Icons.folder_open_outlined,
                label: loc.AppLocalizations.of(sheetContext)!.importFile,
                onTap: () => Navigator.of(sheetContext).pop('import'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    await addSheetRoute?.completed;
    if (!mounted) return;
    switch (action) {
      case 'scan':
        _openScanner();
      case 'folder':
        await _createFolder();
      case 'import':
        await _importImage();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          heroTag: 'home_add',
          onPressed: _showAddSheet,
          backgroundColor: AppColors.primary(context),
          foregroundColor: _onPrimary(context),
          elevation: 3,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
        appBar: _HomeHeader(),
        bottomNavigationBar: AppBottomBar(
          selectedIndex: 0,
          onScan: _openScanner,
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
            children: [
              const SizedBox(height: 20),
              _HeroCard(onScan: _openScanner),
              const SizedBox(height: 24),
              _SectionTitle(loc.AppLocalizations.of(context)!.quickActions),
              const SizedBox(height: 14),
              _QuickActions(
                onScan: _openScannerWithMode,
                onImport: _importImage,
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                loc.AppLocalizations.of(context)!.recentDocuments,
                actionLabel: loc.AppLocalizations.of(context)!.seeAll,
              ),
              const SizedBox(height: 14),
              _RecentDocuments(
                future: _recentDocumentsFuture,
                onRetry: _refreshRecentDocuments,
                onShareDocument: _shareDocument,
                onRenameDocument: _renameDocument,
                onDeleteDocument: _deleteDocument,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSheetHandle extends StatelessWidget {
  const _AddSheetHandle();

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 4,
    decoration: BoxDecoration(
      color: AppColors.border(context),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _HomeAddTile extends StatelessWidget {
  const _HomeAddTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary(context)),
    title: Text(
      label,
      style: TextStyle(color: AppColors.ink(context), fontSize: 14),
    ),
    onTap: onTap,
  );
}

// ───────────────────────────── Header ─────────────────────────────

class _HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // NOTE: if this PNG is dark artwork, it will be hard to see in dark
            // mode. Swap in a dark-variant asset here if you have one.
            Image.asset(
              isDark
                  ? 'assets/03_splash_assets/png/wordmark_dark.png'
                  : 'assets/03_splash_assets/png/wordmark_light.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'Clear',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.ink(context),
              ),
            ),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary(context),
              ),
            ),
            const Spacer(),
            ValueListenableBuilder<int>(
              valueListenable: notificationUnreadCount,
              builder: (context, unread, _) => IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 26,
                    color: AppColors.ink(context),
                  ),
                ),
                tooltip: loc.AppLocalizations.of(context)!.notificationsTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Hero ─────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 178,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: _heroBackground,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: AppColors.border(context)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.AppLocalizations.of(context)!.scanAnythingSaveEverything,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.AppLocalizations.of(context)!.fast_and_smart,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: _heroMutedText,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: onScan,
                    icon: const Icon(Icons.photo_camera_outlined, size: 17),
                    label: Text(
                      loc.AppLocalizations.of(context)!.scanButton,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      // The hero is dark in both themes, so use the bright
                      // accent here for contrast and dark text on top of it.
                      backgroundColor: const Color(0xFF2CC4CF),
                      foregroundColor: const Color(0xFF0B1E26),
                      elevation: 0,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _HeroPaper(),
        ],
      ),
    );
  }
}

class _HeroPaper extends StatelessWidget {
  const _HeroPaper();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 118,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 5; i++) ...[
            FractionallySizedBox(
              widthFactor: i.isEven ? 0.75 : 1,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFBCC8CE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── Quick actions ─────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onScan, required this.onImport});

  final ValueChanged<ScanMode> onScan;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final items = <_QuickAction>[
      _QuickAction(
        Icons.badge_outlined,
        loc.AppLocalizations.of(context)!.idCards,
        () => onScan(ScanMode.idCard),
      ),
      _QuickAction(
        Icons.menu_book_outlined,
        loc.AppLocalizations.of(context)!.passport,
        () => onScan(ScanMode.passport),
      ),
      _QuickAction(
        Icons.qr_code_2_rounded,
        loc.AppLocalizations.of(context)!.qrCode,
        () => onScan(ScanMode.qr),
      ),
      _QuickAction(
        Icons.folder_open_outlined,
        loc.AppLocalizations.of(context)!.import,
        onImport,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 9),
          Expanded(child: _QuickActionTile(action: items[i])),
        ],
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

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
        onTap: action.onTap,
        child: SizedBox(
          height: 82,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 28, color: AppColors.primary(context)),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: TextStyle(fontSize: 11, color: AppColors.ink(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Recent documents ─────────────────────────────

class _RecentDocuments extends StatelessWidget {
  const _RecentDocuments({
    required this.future,
    required this.onRetry,
    required this.onShareDocument,
    required this.onRenameDocument,
    required this.onDeleteDocument,
  });

  final Future<List<RecentDocument>> future;
  final VoidCallback onRetry;
  final ValueChanged<RecentDocument> onShareDocument;
  final ValueChanged<RecentDocument> onRenameDocument;
  final ValueChanged<RecentDocument> onDeleteDocument;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecentDocument>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _RecentDocumentsMessage(
            icon: Icons.error_outline_rounded,
            message: snapshot.error.toString(),
            onRetry: onRetry,
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data!;
        if (docs.isEmpty) {
          return _RecentDocumentsMessage(
            icon: Icons.folder_open_outlined,
            message: loc.AppLocalizations.of(context)!.noDocumentsFound,
          );
        }

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
              for (var i = 0; i < docs.length; i++) ...[
                _DocRow(
                  doc: docs[i],
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => DocumentViewerScreen(document: docs[i]),
                    ),
                  ),
                  onActions: () => _showDocumentActions(context, docs[i]),
                ),
                if (i < docs.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 72,
                    endIndent: 16,
                    color: AppColors.border(context),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showDocumentActions(BuildContext context, RecentDocument document) {
    final localizations = loc.AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  document.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              BottomActionBar(
                actions: [
                  BottomActionBarItem(
                    icon: Icons.share_outlined,
                    label: localizations.share,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onShareDocument(document);
                    },
                  ),
                  BottomActionBarItem(
                    icon: Icons.drive_file_rename_outline,
                    label: localizations.rename,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onRenameDocument(document);
                    },
                  ),
                  BottomActionBarItem(
                    icon: Icons.delete_outline_rounded,
                    label: localizations.delete,
                    iconColor: const Color(0xFFE5484D),
                    backgroundColor: const Color(0xFFFFE5E5),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onDeleteDocument(document);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDocumentsMessage extends StatelessWidget {
  const _RecentDocumentsMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted(context), size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted(context)),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.doc,
    required this.onTap,
    required this.onActions,
  });

  final RecentDocument doc;
  final VoidCallback onTap;
  final VoidCallback onActions;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final modified = DateFormat.yMMMd(locale).add_jm().format(doc.modifiedAt);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        child: Row(
          children: [
            _DocThumb(doc: doc),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
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
                    '${doc.type}  •  ${_formatSize(doc.sizeBytes)}  •  $modified',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: AppColors.textMuted(context),
              ),
              tooltip: MaterialLocalizations.of(context).showMenuTooltip,
              onPressed: onActions,
            ),
          ],
        ),
      ),
    );
  }
}

class _RenameDocumentDialog extends StatefulWidget {
  const _RenameDocumentDialog({required this.title, required this.initialName});

  final String title;
  final String initialName;

  @override
  State<_RenameDocumentDialog> createState() => _RenameDocumentDialogState();
}

class _RenameDocumentDialogState extends State<_RenameDocumentDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
        ),
      ],
    );
  }
}

/// Mini paper thumbnail. Stays white in both themes (it represents a sheet of
/// paper), so it uses fixed colors.
class _DocThumb extends StatefulWidget {
  const _DocThumb({required this.doc});

  final RecentDocument doc;

  @override
  State<_DocThumb> createState() => _DocThumbState();
}

class _DocThumbState extends State<_DocThumb> {
  Uint8List? _pdfBytes;
  bool _pdfLoadFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.doc.type == 'PDF' && widget.doc.path.startsWith('content://')) {
      _loadPdfBytes();
    }
  }

  Future<void> _loadPdfBytes() async {
    try {
      final bytes = await readRecentDocumentBytes(widget.doc);
      if (mounted) setState(() => _pdfBytes = bytes);
    } on Exception catch (error) {
      debugPrint('Could not load PDF thumbnail for ${widget.doc.name}: $error');
      if (mounted) setState(() => _pdfLoadFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final isImage = doc.type == 'JPG' || doc.type == 'PNG';
    final isPdf = doc.type == 'PDF';
    final canLoadImage = isImage && !doc.path.startsWith('content://');
    return Container(
      width: 40,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFE6ECEF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: isPdf && !_pdfLoadFailed
          ? _buildPdfThumbnail(doc)
          : canLoadImage
          ? Image.file(
              File(doc.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _DocumentPlaceholder(),
            )
          : const _DocumentPlaceholder(),
    );
  }

  Widget _buildPdfThumbnail(RecentDocument doc) {
    if (doc.path.startsWith('content://') && _pdfBytes == null) {
      return const Center(
        child: SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }
    return IgnorePointer(
      child: PDFView(
        filePath: doc.path.startsWith('content://') ? null : doc.path,
        pdfData: doc.path.startsWith('content://') ? _pdfBytes : null,
        defaultPage: 0,
        enableSwipe: false,
        autoSpacing: false,
        pageFling: false,
        fitPolicy: FitPolicy.BOTH,
        onError: (error) {
          debugPrint('Could not render PDF thumbnail for ${doc.name}: $error');
          if (mounted) setState(() => _pdfLoadFailed = true);
        },
      ),
    );
  }
}

class _DocumentPlaceholder extends StatelessWidget {
  const _DocumentPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
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

// ───────────────────────────── Shared bits ─────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.actionLabel}) : onAction = null;

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink(context),
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap:
                onAction ??
                () {}, // If onAction is null, do nothing when tapped
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.primary(context),
              ),
            ),
          ),
      ],
    );
  }
}
