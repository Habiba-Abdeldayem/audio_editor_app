import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
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

  Future<void> _openFolder() async {
    if (resultPaths != null && resultPaths!.isNotEmpty) {
      // Open the directory containing the first split file
      final firstFile = resultPaths!.first;
      final directory = p.dirname(firstFile);
      await OpenFilex.open(directory);
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path.split('/').last,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      path,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _openFolder,
                icon: const Icon(Icons.folder_open),
                label: const Text('Open folder'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
