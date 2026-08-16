import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/audio_track.dart';
import '../entities/audio_metadata.dart';
import '../entities/compression_option.dart';

/// Domain-facing contract. The presentation layer (via use cases) depends
/// only on this abstraction; `data/repositories/audio_repository_impl.dart`
/// provides the real implementation backed by just_audio/ffmpeg/audiotags.
abstract class AudioRepository {
  /// Loads an m4a file from [filePath], decodes duration + a downsampled
  /// waveform for display.
  Future<Either<Failure, AudioTrack>> loadAudioFile(String filePath);

  /// Starts/attaches a player session for the given track. Playback control
  /// itself (play/pause/seek) happens through the returned stream-backed
  /// controller obtained via [getPlayerController].
  Future<Either<Failure, Unit>> preparePlayback(String filePath);

  Future<Either<Failure, Unit>> play();
  Future<Either<Failure, Unit>> pause();

  /// Smooth scrubbing: called continuously while the user drags the
  /// waveform, cheap enough to call on every frame.
  Future<Either<Failure, Unit>> seek(Duration position);

  Stream<Duration> get positionStream;
  Stream<bool> get playingStream;

  Future<Either<Failure, Unit>> disposePlayer();

  /// Splits [filePath] into two files at [splitPoint]. Returns the two
  /// resulting file paths in order. Uses stream-copy (no re-encode) so it's
  /// fast and lossless.
  Future<Either<Failure, List<String>>> splitAudio({
    required String filePath,
    required Duration splitPoint,
  });

  /// Builds the list of compression presets with pre-computed estimated
  /// sizes for [filePath], without performing any encoding.
  Future<Either<Failure, List<CompressionOption>>> getCompressionOptions(
    String filePath,
  );

  /// Re-encodes [filePath] at [bitrateKbps]; returns the new file path.
  Future<Either<Failure, String>> compressAudio({
    required String filePath,
    required int bitrateKbps,
    void Function(double progress)? onProgress,
  });

  Future<Either<Failure, AudioMetadata>> readMetadata(String filePath);

  Future<Either<Failure, Unit>> writeMetadata({
    required String filePath,
    required AudioMetadata metadata,
  });

  Future<Either<Failure, int>> getFileSizeBytes(String filePath);

  Future<Either<Failure, String>> renameFile({
    required String filePath,
    required String newName,
  });
}
