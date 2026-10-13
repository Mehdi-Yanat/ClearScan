import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart' as loc;
import '../../services/documents/cloud_document_storage.dart';
import '../../services/documents/recent_documents.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback/app_snackbar.dart';

class CloudStorageScreen extends StatefulWidget {
  const CloudStorageScreen({super.key});

  @override
  State<CloudStorageScreen> createState() => _CloudStorageScreenState();
}

class _CloudStorageScreenState extends State<CloudStorageScreen> {
  List<RecentDocument> _localDocuments = const [];
  List<CloudDocument> _cloudDocuments = const [];
  final Set<String> _selectedPaths = {};
  bool _loading = true;
  bool _uploading = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        loadRecentDocuments(limit: null),
        listCloudDocuments(),
      ]);
      if (!mounted) return;
      setState(() {
        _localDocuments = results[0] as List<RecentDocument>;
        _cloudDocuments = results[1] as List<CloudDocument>
          ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
        _selectedPaths.clear();
      });
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadSelected() async {
    final l10n = loc.AppLocalizations.of(context)!;
    final selected = _localDocuments
        .where((document) => _selectedPaths.contains(document.path))
        .toList(growable: false);
    if (selected.isEmpty) return;

    setState(() => _uploading = true);
    var uploaded = 0;
    try {
      for (final document in selected) {
        await uploadDocument(document);
        uploaded++;
      }
      if (!mounted) return;
      showAppSnackBar(context, l10n.cloudBackupComplete(uploaded));
      await _loadDocuments();
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _error = l10n.cloudBackupPartialFailure(uploaded, error.toString());
        });
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _restore(CloudDocument document) async {
    final l10n = loc.AppLocalizations.of(context)!;
    try {
      final file = await restoreCloudDocument(document);
      if (!mounted) return;
      showAppSnackBar(
        context,
        l10n.cloudRestoreComplete(file.uri.pathSegments.last),
      );
      Navigator.of(context).pop();
    } on Exception catch (error) {
      if (mounted) {
        showAppSnackBar(context, l10n.cloudStorageError(error.toString()));
      }
    }
  }

  Future<void> _delete(CloudDocument document) async {
    final l10n = loc.AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cloudDeleteConfirmTitle),
        content: Text(l10n.cloudDeleteConfirmMessage(document.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cloudCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await deleteCloudDocument(document);
      if (!mounted) return;
      showAppSnackBar(context, l10n.cloudDeleteComplete(document.name));
      await _loadDocuments();
    } on Exception catch (error) {
      if (mounted) {
        showAppSnackBar(context, l10n.cloudDeleteError(error.toString()));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = loc.AppLocalizations.of(context)!;
    final usage = _cloudDocuments.fold<int>(
      0,
      (total, document) => total + document.sizeBytes,
    );
    final selectedCount = _selectedPaths.length;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        foregroundColor: AppColors.ink(context),
        title: Text(l10n.cloudStorage),
        actions: [
          IconButton(
            onPressed: _loading || _uploading || _deleting
                ? null
                : _loadDocuments,
            tooltip: l10n.cloudRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Text(
                    l10n.cloudStorageUsed(_formatBytes(usage)),
                    style: TextStyle(
                      color: AppColors.ink(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.cloudStoragePrivacy,
                    style: TextStyle(color: AppColors.textMuted(context)),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    l10n.cloudBackupChooseDocuments,
                    style: TextStyle(
                      color: AppColors.ink(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_localDocuments.isEmpty)
                    Text(
                      l10n.cloudNoLocalDocuments,
                      style: TextStyle(color: AppColors.textMuted(context)),
                    )
                  else
                    ..._localDocuments.map((document) {
                      final selected = _selectedPaths.contains(document.path);
                      return CheckboxListTile(
                        value: selected,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          document.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.ink(context)),
                        ),
                        subtitle: Text(
                          '${document.type} · ${_formatBytes(document.sizeBytes)}',
                          style: TextStyle(color: AppColors.textMuted(context)),
                        ),
                        onChanged: _uploading || _deleting
                            ? null
                            : (value) => setState(() {
                                if (value == true) {
                                  _selectedPaths.add(document.path);
                                } else {
                                  _selectedPaths.remove(document.path);
                                }
                              }),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: selectedCount == 0 || _uploading || _deleting
                          ? null
                          : _uploadSelected,
                      icon: _uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        _uploading
                            ? l10n.cloudUploading
                            : l10n.cloudBackupSelected(selectedCount),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.cloudBackups,
                    style: TextStyle(
                      color: AppColors.ink(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_cloudDocuments.isEmpty)
                    Text(
                      l10n.cloudNoBackups,
                      style: TextStyle(color: AppColors.textMuted(context)),
                    )
                  else
                    ..._cloudDocuments.map(
                      (document) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          document.name.toLowerCase().endsWith('.pdf')
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined,
                          color: AppColors.primary(context),
                        ),
                        title: Text(
                          document.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.ink(context)),
                        ),
                        subtitle: Text(
                          _formatBytes(document.sizeBytes),
                          style: TextStyle(color: AppColors.textMuted(context)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _uploading || _deleting
                                  ? null
                                  : () => _restore(document),
                              tooltip: l10n.cloudRestore,
                              icon: const Icon(Icons.download_rounded),
                            ),
                            IconButton(
                              onPressed: _uploading || _deleting
                                  ? null
                                  : () => _delete(document),
                              tooltip: l10n.delete,
                              color: AppColors.danger,
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
