import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/audio_local_data_source.dart' show OutputFileInfo;
import '../../domain/usecases/list_output_files.dart';
import '../bloc/settings_cubit.dart';

class OutputFilesPage extends StatefulWidget {
  const OutputFilesPage({super.key});

  @override
  State<OutputFilesPage> createState() => _OutputFilesPageState();
}

class _OutputFilesPageState extends State<OutputFilesPage> {
  List<OutputFileInfo> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final folderName = sl<SettingsCubit>().state.outputFolder;
    final result = await sl<ListOutputFiles>()(folderName);
    result.fold(
      (failure) {
        if (mounted) setState(() => _isLoading = false);
      },
      (files) {
        if (mounted) setState(() { _files = files; _isLoading = false; });
      },
    );
  }

  Future<void> _shareFile(OutputFileInfo file) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final f = File(file.path);
      if (!(await f.exists())) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.fileNoLongerExists)));
        return;
      }
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: file.name,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotShareFile('$e'))));
    }
  }

  Future<void> _deleteFile(OutputFileInfo file) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final f = File(file.path);
      if (await f.exists()) await f.delete();
      setState(() => _files.remove(file));
      messenger.showSnackBar(SnackBar(content: Text('Deleted "${file.name}"')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }

  Future<void> _renameFile(OutputFileInfo file) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: file.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.fileName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.rename),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != file.name) {
      try {
        final oldFile = File(file.path);
        final newPath = '${oldFile.parent.path}/$result';
        await oldFile.rename(newPath);
        setState(() {
          final idx = _files.indexOf(file);
          if (idx != -1) {
            _files[idx] = OutputFileInfo(
              name: result,
              path: newPath,
              sizeBytes: file.sizeBytes,
              modified: file.modified,
            );
          }
        });
        messenger.showSnackBar(SnackBar(content: Text(l10n.renamedTo(result))));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Could not rename: $e')));
      }
    }
  }

  Future<void> _openInFileManager() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final folderName = sl<SettingsCubit>().state.outputFolder;
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'content://com.android.externalstorage.documents/document/primary%3AMusic%2F$folderName',
        type: 'vnd.android.document/directory',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotOpenFolder('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final folderName = sl<SettingsCubit>().state.outputFolder;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.outputFolder),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: l10n.openOutputFolder,
            onPressed: _openInFileManager,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        l10n.outputFolderPath(folderName),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No files yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    return _OutputFileTile(
                      file: file,
                      onShare: () => _shareFile(file),
                      onDelete: () => _confirmDelete(file),
                      onRename: () => _renameFile(file),
                    );
                  },
                ),
    );
  }

  void _confirmDelete(OutputFileInfo file) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rename),
        content: Text('Delete "${file.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () { Navigator.pop(ctx); _deleteFile(file); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _OutputFileTile extends StatelessWidget {
  final OutputFileInfo file;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _OutputFileTile({
    required this.file,
    required this.onShare,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = p.basenameWithoutExtension(file.name);
    final ext = p.extension(file.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.audio_file, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${Formatters.fileSize(file.sizeBytes)}  ·  $ext  ·  ${_formatDate(file.modified)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _ActionIcon(
                icon: Icons.edit,
                tooltip: AppLocalizations.of(context).rename,
                onTap: onRename,
              ),
              _ActionIcon(
                icon: Icons.delete_outline,
                tooltip: 'Delete',
                onTap: onDelete,
              ),
              _ActionIcon(
                icon: Icons.share,
                tooltip: AppLocalizations.of(context).share,
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final hour = dt.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${dt.day}/${dt.month}/${dt.year}  ${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionIcon({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: onTap != null
          ? Theme.of(context).colorScheme.onSurfaceVariant
          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
    );
  }
}
