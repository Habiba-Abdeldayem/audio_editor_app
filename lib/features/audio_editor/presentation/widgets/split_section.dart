import 'package:flutter/material.dart';
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

  Future<void> _shareFile(String filePath) async {
    try {
      print('Attempting to share file: $filePath');
      final file = File(filePath);
      if (!(await file.exists())) {
        print('File does not exist: $filePath');
        return;
      }
      print('File exists, size: ${await file.length()} bytes');

      // Try basic share with text only
      await Share.share('Audio file: ${p.basename(filePath)}\nPath: $filePath');
      print('Share completed successfully');
    } catch (e) {
      print('Error sharing file: $e');
      debugPrint('Error sharing file: $e');
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
                      onPressed: () {
                        print('Share button pressed for: $path');
                        _shareFile(path);
                      },
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
