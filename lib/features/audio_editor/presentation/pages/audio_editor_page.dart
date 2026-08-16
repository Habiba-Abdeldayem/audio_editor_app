import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/formatters.dart';
import '../bloc/audio_editor_cubit.dart';
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
      create: (_) => sl<AudioEditorCubit>(),
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
      context.read<AudioEditorCubit>().loadFile(path);
    }
  }

  void _openCompressSheet(BuildContext context) {
    final cubit = context.read<AudioEditorCubit>();
    cubit.loadCompressionOptions();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<AudioEditorCubit, AudioEditorState>(
          builder: (context, state) {
            return CompressSheet(
              originalSizeBytes: state.track?.fileSizeBytes ?? 0,
              options: state.compressionOptions,
              isLoadingOptions:
                  state.compressionStatus == CompressionStatus.loadingOptions,
              isCompressing:
                  state.compressionStatus == CompressionStatus.compressing,
              isError: state.compressionStatus == CompressionStatus.error,
              errorMessage: state.compressionStatus == CompressionStatus.error
                  ? state.failure?.message
                  : null,
              resultPath: state.compressionStatus == CompressionStatus.done
                  ? state.compressedFilePath
                  : null,
              onOptionSelected: (bitrate) => cubit.compressAudio(bitrate),
            );
          },
        ),
      ),
    );
  }

  void _openMetadataSheet(BuildContext context) {
    final cubit = context.read<AudioEditorCubit>();
    cubit.openMetadataEditor();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<AudioEditorCubit, AudioEditorState>(
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
              onChanged: (draft) => cubit.updateMetadataField(draft),
              onSave: () => cubit.saveMetadata(),
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
      body: BlocConsumer<AudioEditorCubit, AudioEditorState>(
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
            final step = state.loadingStep;
            String message = 'Loading audio...';
            if (step == LoadingStep.fileMetadata) {
              message = 'Reading file info...';
            } else if (step == LoadingStep.waveform) {
              message = 'Generating waveform...';
            } else if (step == LoadingStep.playbackPrep) {
              message = 'Preparing playback...';
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
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
                  onSeek: (pos) => context.read<AudioEditorCubit>().seek(pos),
                ),
                const SizedBox(height: 12),
                PlaybackControls(
                  isPlaying: state.isPlaying,
                  position: state.position,
                  duration: track.duration,
                  onPlayPause: () =>
                      context.read<AudioEditorCubit>().togglePlayPause(),
                  onSkip: (pos) => context.read<AudioEditorCubit>().seek(pos),
                ),
                const SizedBox(height: 20),
                SplitSection(
                  currentPosition: state.position,
                  onSplit: () => context.read<AudioEditorCubit>().splitAudio(),
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
