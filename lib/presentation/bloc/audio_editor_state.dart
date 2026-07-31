import 'package:equatable/equatable.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/audio_metadata.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/compression_option.dart';

enum EditorStatus { initial, loading, ready, error }
enum CompressionStatus { idle, loadingOptions, compressing, done, error }
enum MetadataStatus { idle, loading, editing, saving, saved, error }

class AudioEditorState extends Equatable {
  final EditorStatus status;
  final AudioTrack? track;
  final Duration position;
  final bool isPlaying;
  final Failure? failure;

  // Split
  final List<String>? splitResultPaths;

  // Compression
  final CompressionStatus compressionStatus;
  final List<CompressionOption> compressionOptions;
  final String? compressedFilePath;

  // Metadata
  final MetadataStatus metadataStatus;
  final AudioMetadata? metadata;
  final AudioMetadata? metadataDraft;

  const AudioEditorState({
    this.status = EditorStatus.initial,
    this.track,
    this.position = Duration.zero,
    this.isPlaying = false,
    this.failure,
    this.splitResultPaths,
    this.compressionStatus = CompressionStatus.idle,
    this.compressionOptions = const [],
    this.compressedFilePath,
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
    List<String>? splitResultPaths,
    CompressionStatus? compressionStatus,
    List<CompressionOption>? compressionOptions,
    String? compressedFilePath,
    MetadataStatus? metadataStatus,
    AudioMetadata? metadata,
    AudioMetadata? metadataDraft,
  }) {
    return AudioEditorState(
      status: status ?? this.status,
      track: track ?? this.track,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      failure: clearFailure ? null : (failure ?? this.failure),
      splitResultPaths: splitResultPaths ?? this.splitResultPaths,
      compressionStatus: compressionStatus ?? this.compressionStatus,
      compressionOptions: compressionOptions ?? this.compressionOptions,
      compressedFilePath: compressedFilePath ?? this.compressedFilePath,
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
        splitResultPaths,
        compressionStatus,
        compressionOptions,
        compressedFilePath,
        metadataStatus,
        metadata,
        metadataDraft,
      ];
}
