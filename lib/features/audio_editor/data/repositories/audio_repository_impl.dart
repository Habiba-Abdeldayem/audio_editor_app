import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/audio_metadata.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/compression_option.dart';
import '../../domain/repositories/audio_repository.dart';
import '../datasources/audio_local_data_source.dart';
import '../models/audio_metadata_model.dart';

/// Bridges the domain contract to the concrete datasource. Its only real
/// job is exception -> Failure translation, so every use case gets a clean
/// Either<Failure, T> instead of having to catch plugin-specific exceptions.
class AudioRepositoryImpl implements AudioRepository {
  final AudioLocalDataSource localDataSource;

  const AudioRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, AudioTrack>> loadAudioFile(String filePath) async {
    try {
      final track = await localDataSource.loadAudioFile(filePath);
      return Right(track);
    } on UnsupportedFormatException catch (e) {
      return Left(UnsupportedFormatFailure(e.message));
    } on FileAccessException catch (e) {
      return Left(FileAccessFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> preparePlayback(String filePath) async {
    try {
      await localDataSource.preparePlayback(filePath);
      return const Right(unit);
    } on PlaybackException catch (e) {
      return Left(PlaybackFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> play() async {
    try {
      await localDataSource.play();
      return const Right(unit);
    } on PlaybackException catch (e) {
      return Left(PlaybackFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> pause() async {
    try {
      await localDataSource.pause();
      return const Right(unit);
    } on PlaybackException catch (e) {
      return Left(PlaybackFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> seek(Duration position) async {
    try {
      await localDataSource.seek(position);
      return const Right(unit);
    } on PlaybackException catch (e) {
      return Left(PlaybackFailure(e.message));
    }
  }

  @override
  Stream<Duration> get positionStream => localDataSource.positionStream;

  @override
  Stream<bool> get playingStream => localDataSource.playingStream;

  @override
  Future<Either<Failure, Unit>> disposePlayer() async {
    try {
      await localDataSource.disposePlayer();
      return const Right(unit);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> splitAudio({
    required String filePath,
    required Duration splitPoint,
  }) async {
    try {
      final paths = await localDataSource.splitAudio(
        filePath: filePath,
        splitPoint: splitPoint,
      );
      return Right(paths);
    } on SplitException catch (e) {
      return Left(SplitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CompressionOption>>> getCompressionOptions(
    String filePath,
  ) async {
    try {
      final duration = await localDataSource.getDuration(filePath);

      // Calculate bitrate needed to achieve target file sizes
      // bitrate (kbps) = (target_size_bytes * 8) / (duration_seconds * 1000)
      final durationSeconds = duration.inSeconds.toDouble();
      final bitrateFor16MB = durationSeconds > 0
          ? ((AppConstants.targetFileSize16MB * 8) / (durationSeconds * 1000))
              .round()
          : 128;
      final bitrateFor8MB = durationSeconds > 0
          ? ((AppConstants.targetFileSize8MB * 8) / (durationSeconds * 1000))
              .round()
          : 64;
      final bitrateFor4MB = durationSeconds > 0
          ? ((AppConstants.targetFileSize4MB * 8) / (durationSeconds * 1000))
              .round()
          : 32;

      // Ensure minimum bitrate of 16 kbps
      final safeBitrate16MB = bitrateFor16MB.clamp(16, 320);
      final safeBitrate8MB = bitrateFor8MB.clamp(16, 320);
      final safeBitrate4MB = bitrateFor4MB.clamp(16, 320);

      const presets = [
        (
          CompressionQuality.veryHigh,
          AppConstants.veryHighQualityBitrate,
          'Very High (320 kbps)'
        ),
        (
          CompressionQuality.high,
          AppConstants.highQualityBitrate,
          'High (192 kbps)'
        ),
        (
          CompressionQuality.medium,
          AppConstants.mediumQualityBitrate,
          'Medium (128 kbps)'
        ),
        (
          CompressionQuality.low,
          AppConstants.lowQualityBitrate,
          'Low (64 kbps)'
        ),
        (
          CompressionQuality.veryLow,
          AppConstants.veryLowQualityBitrate,
          'Very Low (32 kbps)'
        ),
        (
          CompressionQuality.voice,
          AppConstants.voiceOptimizedBitrate,
          'Voice (24 kbps)'
        ),
        (
          CompressionQuality.ultraLow,
          AppConstants.ultraLowQualityBitrate,
          'Ultra Low (16 kbps)'
        ),
      ];

      final options = presets
          .map((preset) => CompressionOption(
                quality: preset.$1,
                bitrateKbps: preset.$2,
                label: preset.$3,
                estimatedBytes: Formatters.estimatedSizeBytes(
                  duration: duration,
                  bitrateKbps: preset.$2,
                ),
              ))
          .toList();

      // Add target size options
      final targetSizeOptions = [
        CompressionOption(
          quality: CompressionQuality.low,
          bitrateKbps: safeBitrate16MB,
          label: 'Target: ~16 MB',
          estimatedBytes: AppConstants.targetFileSize16MB,
          isTargetSize: true,
        ),
        CompressionOption(
          quality: CompressionQuality.veryLow,
          bitrateKbps: safeBitrate8MB,
          label: 'Target: ~8 MB',
          estimatedBytes: AppConstants.targetFileSize8MB,
          isTargetSize: true,
        ),
        CompressionOption(
          quality: CompressionQuality.ultraLow,
          bitrateKbps: safeBitrate4MB,
          label: 'Target: ~4 MB',
          estimatedBytes: AppConstants.targetFileSize4MB,
          isTargetSize: true,
        ),
      ];

      // Combine all options, with target size options at the end
      return Right([...options, ...targetSizeOptions]);
    } on UnsupportedFormatException catch (e) {
      return Left(UnsupportedFormatFailure(e.message));
    } on FileAccessException catch (e) {
      return Left(FileAccessFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> compressAudio({
    required String filePath,
    required int bitrateKbps,
    required Duration totalDuration,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final outputPath = await localDataSource.compressAudio(
        filePath: filePath,
        bitrateKbps: bitrateKbps,
        totalDuration: totalDuration,
        onProgress: onProgress,
      );
      return Right(outputPath);
    } on UnsupportedFormatException catch (e) {
      return Left(UnsupportedFormatFailure(e.message));
    } on CompressionException catch (e) {
      return Left(CompressionFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AudioMetadata>> readMetadata(String filePath) async {
    try {
      final metadata = await localDataSource.readMetadata(filePath);
      return Right(metadata);
    } on MetadataException catch (e) {
      return Left(MetadataFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> writeMetadata({
    required String filePath,
    required AudioMetadata metadata,
  }) async {
    try {
      await localDataSource.writeMetadata(
        filePath: filePath,
        metadata: AudioMetadataModel.fromEntity(metadata),
      );
      return const Right(unit);
    } on MetadataException catch (e) {
      return Left(MetadataFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getFileSizeBytes(String filePath) async {
    try {
      final size = await localDataSource.getFileSizeBytes(filePath);
      return Right(size);
    } on FileAccessException catch (e) {
      return Left(FileAccessFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> renameFile({
    required String filePath,
    required String newName,
  }) async {
    try {
      final newPath =
          await localDataSource.renameFile(filePath: filePath, newName: newName);
      return Right(newPath);
    } on FileAccessException catch (e) {
      return Left(FileAccessFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<OutputFileInfo>>> listOutputFiles(String folderName) async {
    try {
      final files = await localDataSource.listOutputFiles(folderName);
      return Right(files);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
