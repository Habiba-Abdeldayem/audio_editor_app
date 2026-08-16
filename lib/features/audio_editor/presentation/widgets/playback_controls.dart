import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';

class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSkip;

  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Formatters.duration(position),
                style: Theme.of(context).textTheme.bodySmall),
            Text(Formatters.duration(duration),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.replay_10),
              tooltip: l10n.back10s,
              onPressed: () {
                final target = position - const Duration(seconds: 10);
                onSkip(target < Duration.zero ? Duration.zero : target);
              },
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              iconSize: 40,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: onPlayPause,
            ),
            const SizedBox(width: 12),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.forward_10),
              tooltip: l10n.forward10s,
              onPressed: () {
                final target = position + const Duration(seconds: 10);
                onSkip(target > duration ? duration : target);
              },
            ),
          ],
        ),
      ],
    );
  }
}
