import 'package:equatable/equatable.dart';

/// The core domain representation of a loaded audio file.
/// Contains nothing about how it was decoded or where it's stored on disk
/// beyond the path itself — no platform types leak in here.
class AudioTrack extends Equatable {
  final String filePath;
  final Duration duration;
  final int fileSizeBytes;

  /// Normalized (0.0–1.0) amplitude samples used to paint the waveform.
  /// Kept in the domain entity (not just a UI widget) so any presentation
  /// surface can render it consistently.
  final List<double> waveformSamples;

  const AudioTrack({
    required this.filePath,
    required this.duration,
    required this.fileSizeBytes,
    required this.waveformSamples,
  });

  AudioTrack copyWith({
    String? filePath,
    Duration? duration,
    int? fileSizeBytes,
    List<double>? waveformSamples,
  }) {
    return AudioTrack(
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      waveformSamples: waveformSamples ?? this.waveformSamples,
    );
  }

  @override
  List<Object?> get props => [filePath, duration, fileSizeBytes, waveformSamples];
}
