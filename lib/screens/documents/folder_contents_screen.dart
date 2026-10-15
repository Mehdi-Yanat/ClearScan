import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart' as loc;
import '../../services/documents/folder_repository.dart';
import '../../services/documents/recent_documents.dart';
import '../../theme/app_theme.dart';
import 'document_viewer_screen.dart';

class FolderContentsScreen extends StatefulWidget {
  const FolderContentsScreen({super.key, required this.folder});

  final DocumentFolder folder;

  @override
  State<FolderContentsScreen> createState() => _FolderContentsScreenState();
}

class _FolderContentsScreenState extends State<FolderContentsScreen> {
  List<RecentDocument> _documents = [];
  bool _loading = true;
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
      final documents = await loadFolderDocuments(widget.folder);
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _loading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openDocument(RecentDocument document) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DocumentViewerScreen(document: document),
      ),
    );
    if (mounted) await _loadDocuments();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(widget.folder.name),
        backgroundColor: AppColors.surface(context),
        foregroundColor: AppColors.ink(context),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loadDocuments,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _documents.isEmpty
          ? Center(
              child: Text(
                loc.AppLocalizations.of(context)!.noDocumentsFound,
                style: TextStyle(color: AppColors.textMuted(context)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _documents.length,
              separatorBuilder: (_, _) =>
                  Divider(color: AppColors.border(context), height: 1),
              itemBuilder: (context, index) {
                final document = _documents[index];
                final modified = DateFormat.yMMMd(
                  Localizations.localeOf(context).toString(),
                ).add_jm().format(document.modifiedAt);
                return ListTile(
                  onTap: () => _openDocument(document),
                  leading: SizedBox(
                    width: 44,
                    height: 52,
                    child: document.type == 'PDF'
                        ? const Icon(
                            Icons.picture_as_pdf_outlined,
                            color: _folderPdfColor,
                            size: 32,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.file(
                              File(document.path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_outlined),
                            ),
                          ),
                  ),
                  title: Text(
                    document.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${document.type} • ${_formatSize(document.sizeBytes)} • $modified',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                );
              },
            ),
    );
  }
}

const _folderPdfColor = Color(0xFF14909A);
