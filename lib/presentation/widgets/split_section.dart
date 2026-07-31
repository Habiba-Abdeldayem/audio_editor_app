import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';

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
              Text('Created:', style: Theme.of(context).textTheme.labelMedium),
              for (final path in resultPaths!)
                Text(
                  path.split('/').last,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
