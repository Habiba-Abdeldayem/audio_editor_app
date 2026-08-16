import 'package:flutter/material.dart';

/// Renders the cached waveform samples and lets the user scrub through the
/// audio by dragging anywhere on it. Deliberately built as a plain
/// CustomPainter + GestureDetector (not a heavier plugin widget) so seek
/// events can be emitted on every pointer-move for frame-smooth navigation,
/// with the actual player seek debounced upstream in the bloc.
class WaveformPlayer extends StatefulWidget {
  final List<double> samples;
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onSeek;
  final double height;

  const WaveformPlayer({
    super.key,
    required this.samples,
    required this.duration,
    required this.position,
    required this.onSeek,
    this.height = 120,
  });

  @override
  State<WaveformPlayer> createState() => _WaveformPlayerState();
}

class _WaveformPlayerState extends State<WaveformPlayer> {
  double? _dragProgress;

  double get _progress {
    if (_dragProgress != null) return _dragProgress!;
    final total = widget.duration.inMilliseconds;
    if (total == 0) return 0;
    return (widget.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  void _updateFromLocalX(double localX, double width) {
    final clamped = localX.clamp(0.0, width);
    final progress = width == 0 ? 0.0 : clamped / width;
    setState(() => _dragProgress = progress);
    final ms = (widget.duration.inMilliseconds * progress).round();
    widget.onSeek(Duration(milliseconds: ms));
  }

  void _onSliderChanged(double value) {
    final ms = (widget.duration.inMilliseconds * value).round();
    widget.onSeek(Duration(milliseconds: ms));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Column(
      children: [
        // Waveform display
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) =>
                  _updateFromLocalX(d.localPosition.dx, width),
              onHorizontalDragUpdate: (d) =>
                  _updateFromLocalX(d.localPosition.dx, width),
              onHorizontalDragEnd: (_) => setState(() => _dragProgress = null),
              onTapUp: (d) => _updateFromLocalX(d.localPosition.dx, width),
              child: SizedBox(
                height: widget.height,
                width: width,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    samples: widget.samples,
                    progress: _progress,
                    playedColor: color,
                    unplayedColor: track,
                  ),
                ),
              ),
            );
          },
        ),
        // Progress bar with seek thumb
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: color,
            inactiveTrackColor: track,
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: _progress,
            onChanged: _onSliderChanged,
          ),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;

  _WaveformPainter({
    required this.samples,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final barCount = samples.length;
    final barWidth = size.width / barCount;
    final playedBars = (barCount * progress).round();
    final centerY = size.height / 2;

    final playedPaint = Paint()..color = playedColor;
    final unplayedPaint = Paint()..color = unplayedColor;

    for (var i = 0; i < barCount; i++) {
      final amplitude = samples[i].clamp(0.0, 1.0);
      final barHeight = (amplitude * size.height).clamp(2.0, size.height);
      final x = i * barWidth;
      final rect = Rect.fromCenter(
        center: Offset(x + barWidth / 2, centerY),
        width: (barWidth * 0.7).clamp(1.0, barWidth),
        height: barHeight,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      canvas.drawRRect(rrect, i < playedBars ? playedPaint : unplayedPaint);
    }

    // Playhead line
    final playheadX = size.width * progress;
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      Paint()
        ..color = playedColor
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.samples != samples ||
        oldDelegate.playedColor != playedColor;
  }
}
