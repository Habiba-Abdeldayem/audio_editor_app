import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../../../../core/utils/formatters.dart';

class SplitSection extends StatelessWidget {
  final Duration currentPosition;
  final VoidCallback onSplit;
  final List<String>? resultPaths;

  const SplitSection({
    super.key,
    required this.currentPosition,
    required this.onSplit,
    this.resultPaths,
  });

  Future<void> _shareFile(BuildContext context, String filePath) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = File(filePath);
      if (!(await file.exists())) {
        messenger.showSnackBar(
          const SnackBar(content: Text('File no longer exists.')),
        );
        return;
      }

      // share_plus resolves this to a content:// URI via its own
      // FileProvider under the hood, instead of a raw file:// Uri. Passing
      // a bare file path/Uri.file() straight into a Share/VIEW Intent is
      // exactly what triggers FileUriExposedException on API 24+ (apps may
      // not expose file:// URIs to other apps) — routing through the
      // provider is the supported fix, not a bigger try/catch around the
      // same call.
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: p.basename(filePath),
        ),
      );

      if (result.status == ShareResultStatus.dismissed) return;
    } on PlatformException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not share file: ${e.message ?? e}')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not share file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final minute = currentPosition.inMinutes;
    final secondsIntoMinute = currentPosition.inSeconds.remainder(60);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Split', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Splits into two files at the current playhead — '
              'minute $minute, ${secondsIntoMinute}s '
              '(${Formatters.duration(currentPosition)}).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onSplit,
              icon: const Icon(Icons.content_cut),
              label: const Text('Split at current position'),
            ),
            if (resultPaths != null) ...[
              const SizedBox(height: 12),
              Text('Created files:',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              for (final path in resultPaths!)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            path.split('/').last,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          Text(
                            path,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _shareFile(context, path),
                      icon: const Icon(Icons.share),
                      tooltip: 'Share',
                      iconSize: 20,
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                'Files saved to: ${resultPaths!.isNotEmpty ? p.dirname(resultPaths!.first) : ""}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
