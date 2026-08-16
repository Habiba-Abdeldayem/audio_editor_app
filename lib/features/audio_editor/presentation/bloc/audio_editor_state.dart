import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/audio_metadata.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/compression_option.dart';
import '../../data/models/audio_metadata_model.dart';

enum EditorStatus { initial, loading, ready, error }

enum LoadingStep { fileMetadata, waveform, playbackPrep }

enum CompressionStatus { idle, loadingOptions, compressing, done, error }

enum MetadataStatus { idle, loading, editing, saving, saved, error }

class AudioEditorState extends Equatable {
  final EditorStatus status;
  final AudioTrack? track;
  final Duration position;
  final bool isPlaying;
  final Failure? failure;
  final LoadingStep? loadingStep;

  // Split
  final bool isSplitting;
  final List<String>? splitResultPaths;

  // Compression
  final CompressionStatus compressionStatus;
  final List<CompressionOption> compressionOptions;
  final String? compressedFilePath;

  // File compression (for split results etc.)
  final CompressionStatus fileCompressionStatus;
  final String? fileCompressingPath;
  final double? compressionProgress;
  final Map<String, String> compressedBySplitPath;

  // Metadata
  final MetadataStatus metadataStatus;
  final AudioMetadata? metadata;
  final AudioMetadataModel? metadataDraft;

  const AudioEditorState({
    this.status = EditorStatus.initial,
    this.track,
    this.position = Duration.zero,
    this.isPlaying = false,
    this.failure,
    this.loadingStep,
    this.isSplitting = false,
    this.splitResultPaths,
    this.compressionStatus = CompressionStatus.idle,
    this.compressionOptions = const [],
    this.compressedFilePath,
    this.fileCompressionStatus = CompressionStatus.idle,
    this.fileCompressingPath,
    this.compressionProgress,
    this.compressedBySplitPath = const {},
    this.metadataStatus = MetadataStatus.idle,
    this.metadata,
    this.metadataDraft,
  });

  factory AudioEditorState.initial() => const AudioEditorState();

  double get progress {
    final total = track?.duration.inMilliseconds ?? 0;
    if (total == 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  AudioEditorState copyWith({
    EditorStatus? status,
    AudioTrack? track,
    Duration? position,
    bool? isPlaying,
    Failure? failure,
    bool clearFailure = false,
    LoadingStep? loadingStep,
    bool? isSplitting,
    List<String>? splitResultPaths,
    CompressionStatus? compressionStatus,
    List<CompressionOption>? compressionOptions,
    String? compressedFilePath,
    CompressionStatus? fileCompressionStatus,
    String? fileCompressingPath,
    double? compressionProgress,
    Map<String, String>? compressedBySplitPath,
    MetadataStatus? metadataStatus,
    AudioMetadata? metadata,
    AudioMetadataModel? metadataDraft,
  }) {
    return AudioEditorState(
      status: status ?? this.status,
      track: track ?? this.track,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      failure: clearFailure ? null : (failure ?? this.failure),
      loadingStep: loadingStep ?? this.loadingStep,
      isSplitting: isSplitting ?? this.isSplitting,
      splitResultPaths: splitResultPaths ?? this.splitResultPaths,
      compressionStatus: compressionStatus ?? this.compressionStatus,
      compressionOptions: compressionOptions ?? this.compressionOptions,
      compressedFilePath: compressedFilePath ?? this.compressedFilePath,
      fileCompressionStatus:
          fileCompressionStatus ?? this.fileCompressionStatus,
      fileCompressingPath: fileCompressingPath ?? this.fileCompressingPath,
      compressionProgress: compressionProgress ?? this.compressionProgress,
      compressedBySplitPath:
          compressedBySplitPath ?? this.compressedBySplitPath,
      metadataStatus: metadataStatus ?? this.metadataStatus,
      metadata: metadata ?? this.metadata,
      metadataDraft: metadataDraft ?? this.metadataDraft,
    );
  }

  @override
  List<Object?> get props => [
        status,
        track,
        position,
        isPlaying,
        failure,
        loadingStep,
        isSplitting,
        splitResultPaths,
        compressionStatus,
        compressionOptions,
        compressedFilePath,
        fileCompressionStatus,
        fileCompressingPath,
        compressionProgress,
        compressedBySplitPath,
        metadataStatus,
        metadata,
        metadataDraft,
      ];
}
