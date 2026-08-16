import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/audio_editor_cubit.dart';
import '../bloc/audio_editor_state.dart';
import '../bloc/settings_cubit.dart';
import '../widgets/compress_sheet.dart';
import '../widgets/metadata_editor_sheet.dart';
import '../widgets/playback_controls.dart';
import '../widgets/settings_sheet.dart';
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

  Future<void> _openFileCompressSheet(
      BuildContext context, String filePath) async {
    final cubit = context.read<AudioEditorCubit>();
    cubit.resetFileCompression();
    int fileSizeBytes = 0;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        fileSizeBytes = await file.length();
      }
    } catch (_) {}
    cubit.loadCompressionOptions(filePath);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<AudioEditorCubit, AudioEditorState>(
          builder: (context, state) {
            return CompressSheet(
              originalSizeBytes: fileSizeBytes,
              options: state.compressionOptions,
              isLoadingOptions:
                  state.compressionStatus == CompressionStatus.loadingOptions,
              isCompressing:
                  state.fileCompressionStatus == CompressionStatus.compressing,
              isError:
                  state.fileCompressionStatus == CompressionStatus.error,
              errorMessage:
                  state.fileCompressionStatus == CompressionStatus.error
                      ? state.failure?.message
                      : null,
              resultPath:
                  state.fileCompressionStatus == CompressionStatus.done
                      ? state.fileCompressedPath
                      : null,
              onOptionSelected: (bitrate) =>
                  cubit.compressFile(filePath: filePath, bitrateKbps: bitrate),
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).audioEditorAppBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppLocalizations.of(context).settings,
            onPressed: () {
              final settingsCubit = context.read<SettingsCubit>();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => BlocProvider.value(
                  value: settingsCubit,
                  child: SettingsSheet(cubit: settingsCubit),
                ),
              );
            },
          ),
        ],
      ),
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
                label: Text(AppLocalizations.of(context).chooseM4aFile),
              ),
            );
          }

          if (state.status == EditorStatus.loading) {
            final step = state.loadingStep;
            final l10n = AppLocalizations.of(context);
            String message = l10n.loadingAudio;
            if (step == LoadingStep.fileMetadata) {
              message = l10n.readingFileInfo;
            } else if (step == LoadingStep.waveform) {
              message = l10n.generatingWaveform;
            } else if (step == LoadingStep.playbackPrep) {
              message = l10n.preparingPlayback;
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
                label: Text(AppLocalizations.of(context).chooseM4aFile),
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
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    Formatters.fileSize(track.fileSizeBytes),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                  isSplitting: state.isSplitting,
                  resultPaths: state.splitResultPaths,
                  onRename: (filePath, newName) =>
                      context.read<AudioEditorCubit>().renameSplitFile(filePath, newName),
                  onCompress: (filePath) =>
                      _openFileCompressSheet(context, filePath),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openCompressSheet(context),
                        icon: const Icon(Icons.compress),
                        label: Text(AppLocalizations.of(context).compress),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openMetadataSheet(context),
                        icon: const Icon(Icons.edit_note),
                        label: Text(AppLocalizations.of(context).metadata),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => _pickFile(context),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(AppLocalizations.of(context).chooseDifferentFile),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
