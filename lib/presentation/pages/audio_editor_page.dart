import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection_container.dart';
import '../../core/utils/formatters.dart';
import '../bloc/audio_editor_bloc.dart';
import '../bloc/audio_editor_event.dart';
import '../bloc/audio_editor_state.dart';
import '../widgets/compress_sheet.dart';
import '../widgets/metadata_editor_sheet.dart';
import '../widgets/playback_controls.dart';
import '../widgets/split_section.dart';
import '../widgets/waveform_player.dart';

class AudioEditorPage extends StatelessWidget {
  const AudioEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AudioEditorBloc>(),
      child: const _AudioEditorView(),
    );
  }
}

class _AudioEditorView extends StatelessWidget {
  const _AudioEditorView();

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m4a'],
    );
    final path = result?.files.single.path;
    if (path != null && context.mounted) {
      context.read<AudioEditorBloc>().add(AudioFilePicked(path));
    }
  }

  void _openCompressSheet(BuildContext context) {
    final bloc = context.read<AudioEditorBloc>();
    bloc.add(const CompressionOptionsRequested());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<AudioEditorBloc, AudioEditorState>(
          builder: (context, state) {
            return CompressSheet(
              originalSizeBytes: state.track?.fileSizeBytes ?? 0,
              options: state.compressionOptions,
              isLoadingOptions: state.compressionStatus == CompressionStatus.loadingOptions,
              isCompressing: state.compressionStatus == CompressionStatus.compressing,
              resultPath: state.compressionStatus == CompressionStatus.done
                  ? state.compressedFilePath
                  : null,
              onOptionSelected: (bitrate) =>
                  bloc.add(CompressionConfirmed(bitrate)),
            );
          },
        ),
      ),
    );
  }

  void _openMetadataSheet(BuildContext context) {
    final bloc = context.read<AudioEditorBloc>();
    bloc.add(const MetadataEditorOpened());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<AudioEditorBloc, AudioEditorState>(
          builder: (context, state) {
            if (state.metadataStatus == MetadataStatus.loading ||
                state.metadataDraft == null) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return MetadataEditorSheet(
              initial: state.metadataDraft!,
              isSaving: state.metadataStatus == MetadataStatus.saving,
              onChanged: (draft) => bloc.add(MetadataFieldChanged(draft)),
              onSave: () => bloc.add(const MetadataSaveRequested()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Editor')),
      body: BlocConsumer<AudioEditorBloc, AudioEditorState>(
        listenWhen: (previous, current) => current.failure != null,
        listener: (context, state) {
          if (state.failure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure!.message)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == EditorStatus.initial) {
            return Center(
              child: FilledButton.icon(
                onPressed: () => _pickFile(context),
                icon: const Icon(Icons.audio_file),
                label: const Text('Choose an .m4a file'),
              ),
            );
          }

          if (state.status == EditorStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final track = state.track;
          if (track == null) {
            return Center(
              child: FilledButton.icon(
                onPressed: () => _pickFile(context),
                icon: const Icon(Icons.audio_file),
                label: const Text('Choose an .m4a file'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  track.filePath.split('/').last,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  Formatters.fileSize(track.fileSizeBytes),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                WaveformPlayer(
                  samples: track.waveformSamples,
                  duration: track.duration,
                  position: state.position,
                  onSeek: (pos) =>
                      context.read<AudioEditorBloc>().add(SeekRequested(pos)),
                ),
                const SizedBox(height: 12),
                PlaybackControls(
                  isPlaying: state.isPlaying,
                  position: state.position,
                  duration: track.duration,
                  onPlayPause: () =>
                      context.read<AudioEditorBloc>().add(const PlayPauseToggled()),
                  onSkip: (pos) =>
                      context.read<AudioEditorBloc>().add(SeekRequested(pos)),
                ),
                const SizedBox(height: 20),
                SplitSection(
                  currentPosition: state.position,
                  onSplit: () =>
                      context.read<AudioEditorBloc>().add(const SplitRequested()),
                  resultPaths: state.splitResultPaths,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openCompressSheet(context),
                        icon: const Icon(Icons.compress),
                        label: const Text('Compress'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openMetadataSheet(context),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Metadata'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => _pickFile(context),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Choose a different file'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
