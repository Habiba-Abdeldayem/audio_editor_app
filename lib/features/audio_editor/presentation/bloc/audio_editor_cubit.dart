import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/compress_audio_file.dart';
import '../../domain/usecases/get_audio_metadata.dart';
import '../../domain/usecases/get_compression_options.dart';
import '../../domain/usecases/load_audio_file.dart';
import '../../domain/usecases/playback_usecases.dart';
import '../../domain/usecases/split_audio_file.dart';
import '../../domain/usecases/update_audio_metadata.dart';
import '../../domain/usecases/rename_audio_file.dart';
import '../../data/models/audio_metadata_model.dart';
import 'audio_editor_state.dart';

class AudioEditorCubit extends Cubit<AudioEditorState> {
  final LoadAudioFile loadAudioFile;
  final SplitAudioFile splitAudioFile;
  final RenameAudioFile renameAudioFile;
  final GetCompressionOptions getCompressionOptions;
  final CompressAudioFile compressAudioFile;
  final GetAudioMetadata getAudioMetadata;
  final UpdateAudioMetadata updateAudioMetadata;
  final PreparePlayback preparePlayback;
  final PlayAudio playAudio;
  final PauseAudio pauseAudio;
  final SeekAudio seekAudio;
  final WatchPosition watchPosition;
  final WatchPlayingState watchPlayingState;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;

  /// Coalesces rapid seek events from a waveform drag gesture into the
  /// latest position only, so we don't spam the player with a seek per
  /// pixel of finger movement — this is what keeps scrubbing smooth
  /// instead of janky.
  Timer? _seekDebounce;

  AudioEditorCubit({
    required this.loadAudioFile,
    required this.splitAudioFile,
    required this.renameAudioFile,
    required this.getCompressionOptions,
    required this.compressAudioFile,
    required this.getAudioMetadata,
    required this.updateAudioMetadata,
    required this.preparePlayback,
    required this.playAudio,
    required this.pauseAudio,
    required this.seekAudio,
    required this.watchPosition,
    required this.watchPlayingState,
  }) : super(AudioEditorState.initial()) {
    _listenToPlayback();
  }

  void _listenToPlayback() {
    _positionSub?.cancel();
    _playingSub?.cancel();
    _positionSub = watchPosition().listen((pos) => _onPositionTicked(pos));
    _playingSub = watchPlayingState()
        .listen((playing) => _onPlayingStateChanged(playing));
  }

  Future<void> loadFile(String filePath) async {
    emit(state.copyWith(
      status: EditorStatus.loading,
      loadingStep: LoadingStep.fileMetadata,
      clearFailure: true,
    ));

    final result = await loadAudioFile(LoadAudioFileParams(filePath));

    await result.fold(
      (failure) async {
        emit(state.copyWith(status: EditorStatus.error, failure: failure));
      },
      (track) async {
        emit(state.copyWith(loadingStep: LoadingStep.waveform));
        // Small delay to allow UI to update before playback prep
        await Future.delayed(const Duration(milliseconds: 50));
        emit(state.copyWith(loadingStep: LoadingStep.playbackPrep));
        final prepared = await preparePlayback(track.filePath);
        prepared.fold(
          (failure) => emit(
              state.copyWith(status: EditorStatus.error, failure: failure)),
          (_) {
            _listenToPlayback();
            emit(state.copyWith(
              status: EditorStatus.ready,
              track: track,
              position: Duration.zero,
              isPlaying: false,
              loadingStep: null,
            ));
          },
        );
      },
    );
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pauseAudio(const NoParams());
    } else {
      await playAudio(const NoParams());
    }
    // isPlaying itself is updated reactively via _onPlayingStateChanged, which
    // comes from the player's own state stream — keeps a single source of
    // truth instead of the cubit guessing at the new state.
  }

  void seek(Duration position) {
    // Update the displayed position immediately (optimistic UI) so the
    // scrubber tracks the finger 1:1 without waiting on the player.
    emit(state.copyWith(position: position));

    _seekDebounce?.cancel();
    _seekDebounce = Timer(const Duration(milliseconds: 40), () {
      seekAudio(position);
    });
  }

  void _onPositionTicked(Duration position) {
    emit(state.copyWith(position: position));
  }

  void _onPlayingStateChanged(bool isPlaying) {
    emit(state.copyWith(isPlaying: isPlaying));
  }

  Future<void> splitAudio() async {
    final track = state.track;
    if (track == null) return;

    // Prevent splitting at the beginning of the audio
    if (state.position.inSeconds < 1) {
      emit(state.copyWith(
        status: EditorStatus.error,
        failure: const ValidationFailure(
            'Please play the audio and seek to a position before splitting'),
      ));
      return;
    }

    // Prevent splitting at the very end of the audio
    if (state.position >= track.duration - const Duration(seconds: 1)) {
      emit(state.copyWith(
        status: EditorStatus.error,
        failure:
            const ValidationFailure('Cannot split at the end of the audio'),
      ));
      return;
    }

    final result = await splitAudioFile(
      SplitAudioFileParams(
          filePath: track.filePath, splitPoint: state.position),
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(status: EditorStatus.error, failure: failure)),
      (paths) =>
          emit(state.copyWith(splitResultPaths: paths, clearFailure: true)),
    );
  }

  Future<void> renameSplitFile(String oldPath, String newName) async {
    final result = await renameAudioFile(
      RenameAudioFileParams(filePath: oldPath, newName: newName),
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(status: EditorStatus.error, failure: failure)),
      (newPath) {
        final paths = List<String>.from(state.splitResultPaths ?? []);
        final idx = paths.indexOf(oldPath);
        if (idx != -1) paths[idx] = newPath;
        emit(state.copyWith(splitResultPaths: paths, clearFailure: true));
      },
    );
  }

  Future<void> loadCompressionOptions() async {
    final track = state.track;
    if (track == null) return;

    emit(state.copyWith(compressionStatus: CompressionStatus.loadingOptions));

    final result = await getCompressionOptions(
        GetCompressionOptionsParams(track.filePath));

    result.fold(
      (failure) => emit(state.copyWith(
        compressionStatus: CompressionStatus.error,
        failure: failure,
      )),
      (options) => emit(state.copyWith(
        compressionStatus: CompressionStatus.idle,
        compressionOptions: options,
      )),
    );
  }

  Future<void> compressAudio(int bitrateKbps) async {
    final track = state.track;
    if (track == null) return;

    emit(state.copyWith(compressionStatus: CompressionStatus.compressing));

    final result = await compressAudioFile(
      CompressAudioFileParams(
          filePath: track.filePath, bitrateKbps: bitrateKbps),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        compressionStatus: CompressionStatus.error,
        failure: failure,
      )),
      (outputPath) => emit(state.copyWith(
        compressionStatus: CompressionStatus.done,
        compressedFilePath: outputPath,
      )),
    );
  }

  Future<void> compressFile({
    required String filePath,
    required int bitrateKbps,
  }) async {
    emit(state.copyWith(
      fileCompressionStatus: CompressionStatus.compressing,
      fileCompressingPath: filePath,
      clearFailure: true,
    ));

    final result = await compressAudioFile(
      CompressAudioFileParams(filePath: filePath, bitrateKbps: bitrateKbps),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        fileCompressionStatus: CompressionStatus.error,
        fileCompressingPath: null,
        failure: failure,
      )),
      (outputPath) => emit(state.copyWith(
        fileCompressionStatus: CompressionStatus.done,
        fileCompressedPath: outputPath,
        fileCompressingPath: null,
      )),
    );
  }

  Future<void> openMetadataEditor() async {
    final track = state.track;
    if (track == null) return;

    emit(state.copyWith(metadataStatus: MetadataStatus.loading));

    final result =
        await getAudioMetadata(GetAudioMetadataParams(track.filePath));

    result.fold(
      (failure) => emit(state.copyWith(
        metadataStatus: MetadataStatus.error,
        failure: failure,
      )),
      (metadata) => emit(state.copyWith(
        metadataStatus: MetadataStatus.editing,
        metadata: metadata,
        metadataDraft: AudioMetadataModel.fromEntity(metadata),
      )),
    );
  }

  void updateMetadataField(AudioMetadataModel draft) {
    emit(state.copyWith(metadataDraft: draft));
  }

  Future<void> saveMetadata() async {
    final track = state.track;
    final draft = state.metadataDraft;
    if (track == null || draft == null) return;

    emit(state.copyWith(metadataStatus: MetadataStatus.saving));

    final result = await updateAudioMetadata(
      UpdateAudioMetadataParams(filePath: track.filePath, metadata: draft),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        metadataStatus: MetadataStatus.error,
        failure: failure,
      )),
      (_) => emit(state.copyWith(
        metadataStatus: MetadataStatus.saved,
        metadata: draft,
      )),
    );
  }

  @override
  Future<void> close() {
    _seekDebounce?.cancel();
    _positionSub?.cancel();
    _playingSub?.cancel();
    return super.close();
  }
}
