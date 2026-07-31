import 'package:equatable/equatable.dart';
import '../../domain/entities/audio_metadata.dart';

abstract class AudioEditorEvent extends Equatable {
  const AudioEditorEvent();
  @override
  List<Object?> get props => [];
}

class AudioFilePicked extends AudioEditorEvent {
  final String filePath;
  const AudioFilePicked(this.filePath);
  @override
  List<Object?> get props => [filePath];
}

class PlayPauseToggled extends AudioEditorEvent {
  const PlayPauseToggled();
}

/// Fired continuously while the user drags the waveform/scrubber — cheap
/// and debounced downstream so navigation stays smooth.
class SeekRequested extends AudioEditorEvent {
  final Duration position;
  const SeekRequested(this.position);
  @override
  List<Object?> get props => [position];
}

class PositionTicked extends AudioEditorEvent {
  final Duration position;
  const PositionTicked(this.position);
  @override
  List<Object?> get props => [position];
}

class PlayingStateChanged extends AudioEditorEvent {
  final bool isPlaying;
  const PlayingStateChanged(this.isPlaying);
  @override
  List<Object?> get props => [isPlaying];
}

/// Splits at the current playhead position (i.e. "current minute").
class SplitRequested extends AudioEditorEvent {
  const SplitRequested();
}

class CompressionOptionsRequested extends AudioEditorEvent {
  const CompressionOptionsRequested();
}

class CompressionConfirmed extends AudioEditorEvent {
  final int bitrateKbps;
  const CompressionConfirmed(this.bitrateKbps);
  @override
  List<Object?> get props => [bitrateKbps];
}

class MetadataEditorOpened extends AudioEditorEvent {
  const MetadataEditorOpened();
}

class MetadataFieldChanged extends AudioEditorEvent {
  final AudioMetadata draft;
  const MetadataFieldChanged(this.draft);
  @override
  List<Object?> get props => [draft];
}

class MetadataSaveRequested extends AudioEditorEvent {
  const MetadataSaveRequested();
}
