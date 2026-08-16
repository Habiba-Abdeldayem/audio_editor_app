import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';

class SplitSection extends StatefulWidget {
  final Duration currentPosition;
  final VoidCallback onSplit;
  final bool isSplitting;
  final List<String>? resultPaths;
  final Future<void> Function(String filePath, String newName)? onRename;
  final void Function(String filePath)? onCompress;

  const SplitSection({
    super.key,
    required this.currentPosition,
    required this.onSplit,
    this.isSplitting = false,
    this.resultPaths,
    this.onRename,
    this.onCompress,
  });

  @override
  State<SplitSection> createState() => _SplitSectionState();
}

class _SplitSectionState extends State<SplitSection> {
  Map<String, int> _fileSizes = {};

  @override
  void didUpdateWidget(covariant SplitSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resultPaths != oldWidget.resultPaths) {
      _loadFileSizes();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.resultPaths != null) _loadFileSizes();
  }

  Future<void> _loadFileSizes() async {
    if (widget.resultPaths == null) return;
    final sizes = <String, int>{};
    for (final path in widget.resultPaths!) {
      try {
        final file = File(path);
        if (await file.exists()) {
          sizes[path] = await file.length();
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _fileSizes = sizes);
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _shareFile(BuildContext context, String filePath) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final file = File(filePath);
      if (!(await file.exists())) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.fileNoLongerExists)),
        );
        return;
      }
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: p.basename(filePath),
        ),
      );
      if (result.status == ShareResultStatus.dismissed) return;
    } on PlatformException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotShareFile(e.message ?? '$e'))),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotShareFile('$e'))),
      );
    }
  }

  Future<void> _showRenameDialog(BuildContext context, String filePath) async {
    final controller = TextEditingController(text: p.basename(filePath));
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
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
    if (result != null && result.isNotEmpty && result != p.basename(filePath)) {
      await widget.onRename?.call(filePath, result);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.renamedTo(result))),
      );
    }
  }

  Future<void> _openInFolder(BuildContext context, String filePath) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final file = File(filePath);
      if (!(await file.exists())) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.fileNoLongerExists)),
        );
        return;
      }
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'content://com.android.externalstorage.documents/document/primary%3AMusic%2FTafsirEditor',
        type: 'vnd.android.document/directory',
        flags: <int>[
          Flag.FLAG_ACTIVITY_NEW_TASK,
        ],
      );
      await intent.launch();
    } catch (e) {
      // Fallback: open via share sheet so user can see the file
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            subject: p.basename(filePath),
          ),
        );
      } catch (_) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenFolder('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final minute = widget.currentPosition.inMinutes;
    final secondsIntoMinute = widget.currentPosition.inSeconds.remainder(60);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.split, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.splitDescription(minute, secondsIntoMinute,
                  Formatters.duration(widget.currentPosition)),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: widget.isSplitting ? null : widget.onSplit,
              icon: widget.isSplitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.content_cut),
              label: Text(widget.isSplitting
                  ? l10n.splitting
                  : l10n.splitAtCurrentPosition),
            ),
            if (widget.resultPaths != null) ...[
              const SizedBox(height: 16),
              Text(l10n.createdFiles,
                  style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              for (final path in widget.resultPaths!)
                _FileTile(
                  path: path,
                  fileSize: _fileSizes[path],
                  formatSize: _formatSize,
                  onShare: () => _shareFile(context, path),
                  onRename: () => _showRenameDialog(context, path),
                  onCompress: () => widget.onCompress?.call(path),
                  onOpenFolder: () => _openInFolder(context, path),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final String path;
  final int? fileSize;
  final String Function(int) formatSize;
  final VoidCallback onShare;
  final VoidCallback onRename;
  final VoidCallback? onCompress;
  final VoidCallback onOpenFolder;

  const _FileTile({
    required this.path,
    required this.fileSize,
    required this.formatSize,
    required this.onShare,
    required this.onRename,
    required this.onCompress,
    required this.onOpenFolder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = p.basenameWithoutExtension(path);
    final ext = p.extension(path);
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.audio_file,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                fileSize != null
                    ? '${formatSize(fileSize!)}  ·  $ext'
                    : ext,
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
                tooltip: l10n.rename,
                onTap: onRename,
              ),
              _ActionIcon(
                icon: Icons.compress,
                tooltip: l10n.compress,
                onTap: onCompress,
              ),
              _ActionIcon(
                icon: Icons.folder_open,
                tooltip: l10n.showInFolder,
                onTap: onOpenFolder,
              ),
              _ActionIcon(
                icon: Icons.share,
                tooltip: l10n.share,
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

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
