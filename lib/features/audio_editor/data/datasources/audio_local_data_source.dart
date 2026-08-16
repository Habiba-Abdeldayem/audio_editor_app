import 'dart:io';
import 'dart:typed_data';
import 'package:audio_waveforms/audio_waveforms.dart' as waveforms;
import 'package:audiotags/audiotags.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
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
  });

  Future<String> compressAudio({
    required String filePath,
    required int bitrateKbps,
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
  static bool _appFolderConfigured = false;

  AudioLocalDataSourceImpl({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    if (!_appFolderConfigured) {
      MediaStore.appFolder = 'audios';
      _appFolderConfigured = true;
    }
  }

  void _assertM4a(String filePath) {
    if (p.extension(filePath).toLowerCase() != '.m4a') {
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
  /// the published result in Music/AudioEditor.
  Future<Directory> _stagingDir(String subfolder) async {
    final cacheDir = await getTemporaryDirectory();
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
    try {
      final saveInfo = await _mediaStore.saveFile(
        tempFilePath: stagingPath,
        // fileName: fileName,
        dirType: DirType.audio,
        dirName: DirName.music,
      );

      if (saveInfo == null) {
        throw FileAccessException(
            'Could not save "$fileName" to the Music folder.');
      }

      // Resolve the content:// URI MediaStore hands back into a normal
      // path so the rest of the app (sharing, "file exists" checks, etc.)
      // can keep working with a plain file path.
      final resolvedPath =
          await _mediaStore.getFilePathFromUri(uriString: saveInfo.uri.toString());
      return resolvedPath ?? saveInfo.uri.toString();
    } finally {
      // saveFile() copies the bytes into MediaStore's storage, so the
      // staging copy is redundant the moment it returns (success or not —
      // don't leave partial files behind on failure either).
      final stagingFile = File(stagingPath);
      if (await stagingFile.exists()) {
        await stagingFile.delete();
      }
    }
  }

  @override
  Future<List<String>> splitAudio({
    required String filePath,
    required Duration splitPoint,
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

      // Publish both parts to Music/AudioEditor so they're immediately
      // visible in the file manager, then clean up the staging copies.
      final publishedA = await _publishToMusic(stagingA);
      final publishedB = await _publishToMusic(stagingB);

      return [publishedA, publishedB];
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
  }) async {
    _assertM4a(filePath);
    final stagingDir = await _stagingDir('Compressed');
    final baseName = p.basenameWithoutExtension(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final stagingPath = p.join(
        stagingDir.path, '${baseName}_${bitrateKbps}kbps_$timestamp.m4a');

    // Many .m4a files carry embedded cover art as an attached-picture
    // "video" stream. Without telling ffmpeg what to do with it, it tries
    // to re-encode that stream through the default video codec, which is
    // what makes compression appear to hang indefinitely with no error —
    // the audio track finishes but the process never returns. "-vn"
    // explicitly drops any video/image stream so only the audio is
    // touched.
    final cmd = '-y -i "$filePath" -vn -c:a aac -b:a ${bitrateKbps}k '
        '-movflags +faststart "$stagingPath"';

    try {
      // Belt-and-braces timeout: whatever the cause, the UI must never be
      // left spinning forever. If ffmpeg doesn't finish in a reasonable
      // window, cancel it and surface a real error instead.
      final session = await FFmpegKit.execute(cmd).timeout(
        const Duration(minutes: 5),
        onTimeout: () async {
          await FFmpegKit.cancel();
          throw CompressionException(
              'Compression timed out after 5 minutes.');
        },
      );

      final returnCode = await session.getReturnCode();
      if (returnCode == null || returnCode.isValueSuccess() == false) {
        final logs = await session.getAllLogsAsString();
        throw CompressionException('FFmpeg compression failed: $logs');
      }

      if (!(await File(stagingPath).exists())) {
        throw CompressionException('Compressed file was not created.');
      }

      // Publish to Music/AudioEditor so it's visible directly in the file
      // manager, then clean up the staging copy.
      return await _publishToMusic(stagingPath);
    } on CompressionException {
      rethrow;
    } catch (e) {
      // Any other unexpected failure (I/O, plugin channel error, etc.)
      // must still resolve to a CompressionException so it reaches the
      // UI as a proper failure state rather than an unhandled exception
      // that leaves the caller's Future — and the spinner — hanging.
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
    _assertM4a(filePath);
    try {
      // A short-lived, throwaway player instance so this doesn't disturb
      // whatever is currently loaded in the main playback player.
      final probe = AudioPlayer();
      final duration = await probe.setFilePath(filePath) ?? Duration.zero;
      await probe.dispose();
      return duration;
    } catch (e) {
      throw FileAccessException('Failed to probe duration: $e');
    }
  }
}
