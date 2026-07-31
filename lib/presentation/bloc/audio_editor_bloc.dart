import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/usecases/usecase.dart';
import '../../domain/usecases/compress_audio_file.dart';
import '../../domain/usecases/get_audio_metadata.dart';
import '../../domain/usecases/get_compression_options.dart';
import '../../domain/usecases/load_audio_file.dart';
import '../../domain/usecases/playback_usecases.dart';
import '../../domain/usecases/split_audio_file.dart';
import '../../domain/usecases/update_audio_metadata.dart';
import 'audio_editor_event.dart';
import 'audio_editor_state.dart';

class AudioEditorBloc extends Bloc<AudioEditorEvent, AudioEditorState> {
  final LoadAudioFile loadAudioFile;
  final SplitAudioFile splitAudioFile;
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

  AudioEditorBloc({
    required this.loadAudioFile,
    required this.splitAudioFile,
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
    on<AudioFilePicked>(_onFilePicked);
    on<PlayPauseToggled>(_onPlayPauseToggled);
    on<SeekRequested>(_onSeekRequested);
    on<PositionTicked>(_onPositionTicked);
    on<PlayingStateChanged>(_onPlayingStateChanged);
    on<SplitRequested>(_onSplitRequested);
    on<CompressionOptionsRequested>(_onCompressionOptionsRequested);
    on<CompressionConfirmed>(_onCompressionConfirmed);
    on<MetadataEditorOpened>(_onMetadataEditorOpened);
    on<MetadataFieldChanged>(_onMetadataFieldChanged);
    on<MetadataSaveRequested>(_onMetadataSaveRequested);
  }

  Future<void> _onFilePicked(
    AudioFilePicked event,
    Emitter<AudioEditorState> emit,
  ) async {
    emit(state.copyWith(status: EditorStatus.loading, clearFailure: true));

    final result = await loadAudioFile(LoadAudioFileParams(event.filePath));

    await result.fold(
      (failure) async {
        emit(state.copyWith(status: EditorStatus.error, failure: failure));
      },
      (track) async {
        final prepared = await preparePlayback(track.filePath);
        prepared.fold(
          (failure) => emit(state.copyWith(status: EditorStatus.error, failure: failure)),
          (_) {
            _listenToPlayback();
            emit(state.copyWith(
              status: EditorStatus.ready,
              track: track,
              position: Duration.zero,
              isPlaying: false,
            ));
          },
        );
      },
    );
  }

  void _listenToPlayback() {
    _positionSub?.cancel();
    _playingSub?.cancel();
    _positionSub = watchPosition().listen((pos) => add(PositionTicked(pos)));
    _playingSub =
        watchPlayingState().listen((playing) => add(PlayingStateChanged(playing)));
  }

  Future<void> _onPlayPauseToggled(
    PlayPauseToggled event,
    Emitter<AudioEditorState> emit,
  ) async {
    if (state.isPlaying) {
      await pauseAudio(const NoParams());
    } else {
      await playAudio(const NoParams());
    }
    // isPlaying itself is updated reactively via PlayingStateChanged, which
    // comes from the player's own state stream — keeps a single source of
    // truth instead of the bloc guessing at the new state.
  }

  Future<void> _onSeekRequested(
    SeekRequested event,
    Emitter<AudioEditorState> emit,
  ) async {
    // Update the displayed position immediately (optimistic UI) so the
    // scrubber tracks the finger 1:1 without waiting on the player.
    emit(state.copyWith(position: event.position));

    _seekDebounce?.cancel();
    _seekDebounce = Timer(const Duration(milliseconds: 40), () {
      seekAudio(event.position);
    });
  }

  void _onPositionTicked(PositionTicked event, Emitter<AudioEditorState> emit) {
    emit(state.copyWith(position: event.position));
  }

  void _onPlayingStateChanged(
    PlayingStateChanged event,
    Emitter<AudioEditorState> emit,
  ) {
    emit(state.copyWith(isPlaying: event.isPlaying));
  }

  Future<void> _onSplitRequested(
    SplitRequested event,
    Emitter<AudioEditorState> emit,
  ) async {
    final track = state.track;
    if (track == null) return;

    final result = await splitAudioFile(
      SplitAudioFileParams(filePath: track.filePath, splitPoint: state.position),
    );

    result.fold(
      (failure) => emit(state.copyWith(status: EditorStatus.error, failure: failure)),
      (paths) => emit(state.copyWith(splitResultPaths: paths, clearFailure: true)),
    );
  }

  Future<void> _onCompressionOptionsRequested(
    CompressionOptionsRequested event,
    Emitter<AudioEditorState> emit,
  ) async {
    final track = state.track;
    if (track == null) return;

    emit(state.copyWith(compressionStatus: CompressionStatus.loadingOptions));

    final result = await getCompressionOptions(
      GetCompressionOptionsParams(track.filePath),
    );

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

  Future<void> _onCompressionConfirmed(
    CompressionConfirmed event,
    Emitter<AudioEditorState> emit,
  ) async {
    final track = state.track;
    if (track == null) return;

    emit(state.copyWith(compressionStatus: CompressionStatus.compressing));

    final result = await compressAudioFile(
      CompressAudioFileParams(filePath: track.filePath, bitrateKbps: event.bitrateKbps),
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

  Future<void> _onMetadataEditorOpened(
    MetadataEditorOpened event,
    Emitter<AudioEditorState> emit,
  ) async {
    final track = state.track;
    if (track == null) return;

    emit(state.copyWith(metadataStatus: MetadataStatus.loading));

    final result = await getAudioMetadata(GetAudioMetadataParams(track.filePath));

    result.fold(
      (failure) => emit(state.copyWith(
        metadataStatus: MetadataStatus.error,
        failure: failure,
      )),
      (metadata) => emit(state.copyWith(
        metadataStatus: MetadataStatus.editing,
        metadata: metadata,
        metadataDraft: metadata,
      )),
    );
  }

  void _onMetadataFieldChanged(
    MetadataFieldChanged event,
    Emitter<AudioEditorState> emit,
  ) {
    emit(state.copyWith(metadataDraft: event.draft));
  }

  Future<void> _onMetadataSaveRequested(
    MetadataSaveRequested event,
    Emitter<AudioEditorState> emit,
  ) async {
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
