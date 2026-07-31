import '../../domain/entities/audio_track.dart';

class AudioTrackModel extends AudioTrack {
  const AudioTrackModel({
    required super.filePath,
    required super.duration,
    required super.fileSizeBytes,
    required super.waveformSamples,
  });

  factory AudioTrackModel.fromEntity(AudioTrack track) => AudioTrackModel(
        filePath: track.filePath,
        duration: track.duration,
        fileSizeBytes: track.fileSizeBytes,
        waveformSamples: track.waveformSamples,
      );
}
