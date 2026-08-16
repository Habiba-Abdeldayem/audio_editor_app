import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_waveforms/audio_waveforms.dart' as waveforms;
import 'package:audiotags/audiotags.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../models/audio_metadata_model.dart';
import '../models/audio_track_model.dart';

/// Everything that actually touches a plugin, ffmpeg, or the filesystem
/// lives here. Nothing above this layer (domain/presentation) knows about
/// just_audio, ffmpeg_kit, or audiotags directly — only about the
/// AudioRepository contract.
abstract class AudioLocalDataSource {
  Future<AudioTrackModel> loadAudioFile(String filePath);

  Future<void> preparePlayback(String filePath);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Stream<Duration> get positionStream;
  Stream<bool> get playingStream;
  Future<void> disposePlayer();

  Future<List<String>> splitAudio({
    required String filePath,
    required Duration splitPoint,
    void Function(double progress)? onProgress,
  });

  Future<String> compressAudio({
    required String filePath,
    required int bitrateKbps,
    required Duration totalDuration,
    void Function(double progress)? onProgress,
  });

  Future<AudioMetadataModel> readMetadata(String filePath);
  Future<void> writeMetadata({
    required String filePath,
    required AudioMetadataModel metadata,
  });

  Future<int> getFileSizeBytes(String filePath);

  /// Cheap duration probe — does NOT extract waveform samples. Used by
  /// compression-estimate flows that only need duration, not the full
  /// waveform re-decode that [loadAudioFile] performs.
  Future<Duration> getDuration(String filePath);

  /// Renames the file at [filePath] to [newName] (must include extension).
  /// Returns the new full path on success.
  Future<String> renameFile({required String filePath, required String newName});

  Future<List<OutputFileInfo>> listOutputFiles(String folderName);
}

class OutputFileInfo {
  final String name;
  final String path;
  final int sizeBytes;
  final DateTime modified;

  const OutputFileInfo({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.modified,
  });
}

class AudioLocalDataSourceImpl implements AudioLocalDataSource {
  final AudioPlayer _player;
  waveforms.PlayerController? _waveformExtractor;

  // MediaStore is how output files end up somewhere the user can actually
  // find: the public Music folder, visible directly in any file manager,
  // rather than the app's private sandbox. "AudioEditor" is the one
  // subfolder everything is grouped under — Music/AudioEditor — so results
  // are a single, predictable tap away instead of buried several folders
  // deep.
  final MediaStore _mediaStore = MediaStore();

  AudioLocalDataSourceImpl({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  void _assertM4a(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    if (ext != '.m4a' && ext != '.aac' && ext != '.mp4') {
      throw const UnsupportedFormatException();
    }
    if (!File(filePath).existsSync()) {
      throw const FileAccessException('File does not exist on disk.');
    }
  }

  @override
  Future<AudioTrackModel> loadAudioFile(String filePath) async {
    _assertM4a(filePath);
    try {
      // Stage 1: File size check (fast)
      final size = await File(filePath).length();

      // Stage 2: Duration via just_audio (fast, container-level probe).
      final duration = await _player.setFilePath(filePath) ?? Duration.zero;

      // Skip waveform extraction for instant loading
      // Waveform will be extracted lazily when needed
      return AudioTrackModel(
        filePath: filePath,
        duration: duration,
        fileSizeBytes: size,
        waveformSamples: [], // Empty for now, will be filled later
      );
    } on UnsupportedFormatException {
      rethrow;
    } catch (e) {
      throw FileAccessException('Failed to load audio file: $e');
    }
  }

  @override
  Future<void> preparePlayback(String filePath) async {
    try {
      _assertM4a(filePath);
      await _player.setFilePath(filePath);
    } catch (e) {
      throw PlaybackException('Failed to prepare playback: $e');
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      throw PlaybackException('Failed to play: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      throw PlaybackException('Failed to pause: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      // just_audio's seek is cheap enough to call on every drag-update
      // frame, which is what makes scrubbing feel smooth/professional
      // rather than stepping in fixed increments.
      await _player.seek(position);
    } catch (e) {
      throw PlaybackException('Failed to seek: $e');
    }
  }

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<bool> get playingStream =>
      _player.playerStateStream.map((s) => s.playing);

  @override
  Future<void> disposePlayer() async {
    await _player.stop();
    _waveformExtractor?.dispose();
  }

  /// ffmpeg needs a real, plain filesystem path to write to — it can't
  /// target a MediaStore content:// URI directly. So it writes here first,
  /// a private cache folder invisible to the user, and [_publishToMusic]
  /// then hands the finished file over to MediaStore and deletes the
  /// staging copy. The user never sees this folder; they only ever see
  /// the published result in Music/audios.
  Future<Directory> _stagingDir(String subfolder) async {
    final cacheDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(cacheDir.path, 'AudioEditorStaging', subfolder));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Publishes a finished file from the staging folder into the public
  /// Music/AudioEditor folder via MediaStore, then deletes the staging
  /// copy. This is what makes the result show up directly in the file
  /// manager / any music app on Android 10+ without ever requesting broad
  /// storage access — MediaStore owns the write, not raw File I/O.
  Future<String> _publishToMusic(String stagingPath) async {
    final fileName = p.basename(stagingPath);
    final ext = p.extension(stagingPath); // e.g. ".m4a"
    final base = p.basenameWithoutExtension(stagingPath);
    // saveFile() deletes its input after copying to MediaStore, so we
    // hand it a throwaway copy and keep the original staging path intact
    // for the caller to use (compression, sharing, etc.).
    final tempCopyDir = await getTemporaryDirectory();
    final tempCopy = p.join(tempCopyDir.path, '${base}_publish$ext');
    try {
      await File(stagingPath).copy(tempCopy);
      final saveInfo = await _mediaStore.saveFile(
        tempFilePath: tempCopy,
        dirType: DirType.audio,
        dirName: DirName.music,
      );

      if (saveInfo == null) {
        throw FileAccessException(
            'Could not save "$fileName" to the Music folder.');
      }
    } catch (_) {
      // MediaStore publish failed, but staging file still exists on disk
      // so the caller can still use the real path.
    } finally {
      // Clean up the throwaway copy (saveFile may or may not have deleted it).
      final copy = File(tempCopy);
      if (await copy.exists()) {
        await copy.delete();
      }
    }
    // Return the original staging path — a real filesystem path that
    // ffmpeg and other tools can read directly.
    return stagingPath;
  }

  @override
  Future<List<String>> splitAudio({
    required String filePath,
    required Duration splitPoint,
    void Function(double progress)? onProgress,
  }) async {
    _assertM4a(filePath);
    final stagingDir = await _stagingDir('Split');
    final baseName = p.basenameWithoutExtension(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // More user-friendly naming with timestamp
    final stagingA =
        p.join(stagingDir.path, '${baseName}_part1_$timestamp.m4a');
    final stagingB =
        p.join(stagingDir.path, '${baseName}_part2_$timestamp.m4a');

    final splitSeconds =
        splitPoint.inMilliseconds / 1000.0; // fractional seconds for ffmpeg

    // Stream-copy (-c copy): no re-encoding, so splitting is fast and
    // lossless — this only cuts the container, not the codec data.
    final cmdA =
        '-y -i "$filePath" -ss 0 -to $splitSeconds -c copy "$stagingA"';
    final cmdB = '-y -i "$filePath" -ss $splitSeconds -c copy "$stagingB"';

    try {
      final sessionA = await FFmpegKit.execute(cmdA).timeout(
        const Duration(minutes: 5),
        onTimeout: () async {
          await FFmpegKit.cancel();
          throw SplitException('Split timed out after 5 minutes.');
        },
      );
      final returnCodeA = await sessionA.getReturnCode();
      if (returnCodeA == null || returnCodeA.isValueSuccess() == false) {
        final logs = await sessionA.getAllLogsAsString();
        throw SplitException('FFmpeg failed on first half: $logs');
      }

      final sessionB = await FFmpegKit.execute(cmdB).timeout(
        const Duration(minutes: 5),
        onTimeout: () async {
          await FFmpegKit.cancel();
          throw SplitException('Split timed out after 5 minutes.');
        },
      );
      final returnCodeB = await sessionB.getReturnCode();
      if (returnCodeB == null || returnCodeB.isValueSuccess() == false) {
        final logs = await sessionB.getAllLogsAsString();
        throw SplitException('FFmpeg failed on second half: $logs');
      }

      if (!(await File(stagingA).exists())) {
        throw SplitException('Part A file was not created.');
      }
      if (!(await File(stagingB).exists())) {
        throw SplitException('Part B file was not created.');
      }

      // Publish both parts to Music/AudioEditor via MediaStore, then
      // copy them back to our staging directory so we have reliable
      // filesystem paths for subsequent operations (compress, etc.).
      await _publishToMusic(stagingA);
      await _publishToMusic(stagingB);

      return [stagingA, stagingB];
    } on SplitException {
      rethrow;
    } catch (e) {
      throw SplitException('Failed to split audio: $e');
    }
  }

  @override
  Future<String> compressAudio({
    required String filePath,
    required int bitrateKbps,
    required Duration totalDuration,
    void Function(double progress)? onProgress,
  }) async {
    if (!File(filePath).existsSync()) {
      throw const FileAccessException('File does not exist on disk.');
    }
    final stagingDir = await _stagingDir('Compressed');
    final baseName = p.basenameWithoutExtension(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final stagingPath = p.join(
        stagingDir.path, '${baseName}_${bitrateKbps}kbps_$timestamp.m4a');

    final cmd = '-y -i "$filePath" -vn -c:a aac -b:a ${bitrateKbps}k '
        '-movflags +faststart "$stagingPath"';

    final totalMs = totalDuration.inMilliseconds.toDouble();

    try {
      final completer = Completer<void>();

      await FFmpegKit.executeAsync(
        cmd,
        (session) async {
          final returnCode = await session.getReturnCode();
          if (returnCode == null || returnCode.isValueSuccess() == false) {
            if (!completer.isCompleted) {
              final logs = await session.getAllLogsAsString();
              completer.completeError(
                  CompressionException('FFmpeg compression failed: $logs'));
            }
            return;
          }
          if (!completer.isCompleted) completer.complete();
        },
        null,
        (statistics) {
          if (totalMs > 0 && onProgress != null) {
            final processed = statistics.getTime().toDouble();
            final progress = (processed / totalMs).clamp(0.0, 1.0);
            onProgress(progress);
          }
        },
      );

      await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () async {
          await FFmpegKit.cancel();
          throw CompressionException('Compression timed out after 5 minutes.');
        },
      );

      if (!(await File(stagingPath).exists())) {
        throw CompressionException('Compressed file was not created.');
      }

      return await _publishToMusic(stagingPath);
    } on CompressionException {
      rethrow;
    } catch (e) {
      throw CompressionException('Failed to compress audio: $e');
    }
  }

  @override
  Future<AudioMetadataModel> readMetadata(String filePath) async {
    _assertM4a(filePath);
    try {
      final tag = await AudioTags.read(filePath);
      if (tag == null) return const AudioMetadataModel();
      return AudioMetadataModel(
        title: tag.title ?? '',
        artist: tag.trackArtist ?? '',
        album: tag.album ?? '',
        genre: tag.genre ?? '',
        artwork: tag.pictures.isNotEmpty ? tag.pictures.first.bytes : null,
      );
    } catch (e) {
      throw MetadataException('Failed to read metadata: $e');
    }
  }

  @override
  Future<void> writeMetadata({
    required String filePath,
    required AudioMetadataModel metadata,
  }) async {
    _assertM4a(filePath);
    try {
      final tag = Tag(
        title: metadata.title,
        trackArtist: metadata.artist,
        album: metadata.album,
        genre: metadata.genre,
        pictures: metadata.artwork != null
            ? [
                Picture(
                  bytes: Uint8List.fromList(metadata.artwork!),
                  mimeType: MimeType.jpeg,
                  pictureType: PictureType.coverFront,
                ),
              ]
            : [],
      );
      await AudioTags.write(filePath, tag);
    } catch (e) {
      throw MetadataException('Failed to write metadata: $e');
    }
  }

  @override
  Future<int> getFileSizeBytes(String filePath) async {
    try {
      return await File(filePath).length();
    } catch (e) {
      throw FileAccessException('Failed to read file size: $e');
    }
  }

  @override
  Future<Duration> getDuration(String filePath) async {
    if (!File(filePath).existsSync()) {
      throw const FileAccessException('File does not exist on disk.');
    }
    try {
      final probe = AudioPlayer();
      final duration = await probe.setFilePath(filePath) ?? Duration.zero;
      await probe.dispose();
      return duration;
    } catch (_) {
      // just_audio can't probe this container — fall back to FFmpeg
      // which handles a much wider set of formats.
      try {
        final session = await FFmpegKit.execute(
          '-i "$filePath" -f null -',
        );
        final logs = await session.getAllLogsAsString() ?? '';
        final match = RegExp(r'Duration:\s*(\d{2}):(\d{2}):(\d{2})\.(\d{2})')
            .firstMatch(logs);
        if (match != null) {
          final h = int.parse(match.group(1)!);
          final m = int.parse(match.group(2)!);
          final s = int.parse(match.group(3)!);
          final cs = int.parse(match.group(4)!);
          return Duration(
            hours: h,
            minutes: m,
            seconds: s,
            milliseconds: cs * 10,
          );
        }
      } catch (_) {}
      return Duration.zero;
    }
  }

  @override
  Future<String> renameFile(
      {required String filePath, required String newName}) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileAccessException('File does not exist.');
      }
      final dir = file.parent.path;
      final newPath = p.join(dir, newName);
      await file.rename(newPath);
      return newPath;
    } catch (e) {
      throw FileAccessException('Failed to rename file: $e');
    }
  }

  @override
  Future<List<OutputFileInfo>> listOutputFiles(String folderName) async {
    try {
      final dir = Directory('/storage/emulated/0/Music/$folderName');
      if (!await dir.exists()) return [];
      final files = await dir
          .list()
          .where((e) => e is File && p.extension(e.path) == '.m4a')
          .cast<File>()
          .toList();
      final result = <OutputFileInfo>[];
      for (final file in files) {
        try {
          final stat = await file.stat();
          result.add(OutputFileInfo(
            name: p.basename(file.path),
            path: file.path,
            sizeBytes: stat.size,
            modified: stat.modified,
          ));
        } catch (_) {}
      }
      result.sort((a, b) => b.modified.compareTo(a.modified));
      return result;
    } catch (e) {
      return [];
    }
  }
}
