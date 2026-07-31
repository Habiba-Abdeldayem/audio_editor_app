import 'dart:io';
import 'dart:typed_data';
import 'package:audio_waveforms/audio_waveforms.dart' as waveforms;
import 'package:audiotags/audiotags.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:just_audio/just_audio.dart';
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

  AudioLocalDataSourceImpl({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

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

  Future<Directory> _outputDir() async {
    // On Android, use the standard external storage path which is visible
    // Try to get the external storage directory
    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      // Navigate to the root of external storage and use Downloads
      final storageRoot = externalDir.parent.parent
          .parent; // Go up from /storage/emulated/0/Android/data/... to /storage/emulated/0
      final downloadsPath =
          Directory(p.join(storageRoot.path, 'Download', 'AudioEditor'));

      if (!downloadsPath.existsSync()) {
        downloadsPath.createSync(recursive: true);
      }
      return downloadsPath;
    }

    // Fallback to app documents
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDir.path, 'audio_editor_output'));
  }

  @override
  Future<List<String>> splitAudio({
    required String filePath,
    required Duration splitPoint,
  }) async {
    _assertM4a(filePath);
    final outDir = await _outputDir();
    final baseName = p.basenameWithoutExtension(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final partA = p.join(outDir.path, '${baseName}_part1_$timestamp.m4a');
    final partB = p.join(outDir.path, '${baseName}_part2_$timestamp.m4a');

    final splitSeconds =
        splitPoint.inMilliseconds / 1000.0; // fractional seconds for ffmpeg

    // Stream-copy (-c copy): no re-encoding, so splitting is fast and
    // lossless — this only cuts the container, not the codec data.
    final cmdA = '-y -i "$filePath" -ss 0 -to $splitSeconds -c copy "$partA"';
    final cmdB = '-y -i "$filePath" -ss $splitSeconds -c copy "$partB"';

    final sessionA = await FFmpegKit.execute(cmdA);
    final returnCodeA = await sessionA.getReturnCode();
    if (returnCodeA!.isValueSuccess() == false) {
      final logs = await sessionA.getAllLogsAsString();
      throw SplitException('FFmpeg failed on first half: $logs');
    }

    final sessionB = await FFmpegKit.execute(cmdB);
    final returnCodeB = await sessionB.getReturnCode();
    if (returnCodeB!.isValueSuccess() == false) {
      final logs = await sessionB.getAllLogsAsString();
      throw SplitException('FFmpeg failed on second half: $logs');
    }

    return [partA, partB];
  }

  @override
  Future<String> compressAudio({
    required String filePath,
    required int bitrateKbps,
  }) async {
    _assertM4a(filePath);
    final outDir = await _outputDir();
    final baseName = p.basenameWithoutExtension(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath =
        p.join(outDir.path, '${baseName}_${bitrateKbps}kbps_$timestamp.m4a');

    final cmd =
        '-y -i "$filePath" -c:a aac -b:a ${bitrateKbps}k -movflags +faststart "$outputPath"';

    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();
    if (returnCode!.isValueSuccess() == false) {
      final logs = await session.getAllLogsAsString();
      throw CompressionException('FFmpeg compression failed: $logs');
    }

    return outputPath;
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
