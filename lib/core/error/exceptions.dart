/// Raw exceptions thrown by the data layer (datasources, ffmpeg calls, tag
/// libraries). These are caught by the repository implementation and mapped
/// to Failures before crossing into the domain layer.
class FileAccessException implements Exception {
  final String message;
  const FileAccessException([this.message = 'Could not access the audio file.']);
}

class UnsupportedFormatException implements Exception {
  final String message;
  const UnsupportedFormatException([this.message = 'Only .m4a files are supported.']);
}

class PlaybackException implements Exception {
  final String message;
  const PlaybackException([this.message = 'Playback failed.']);
}

class SplitException implements Exception {
  final String message;
  const SplitException([this.message = 'FFmpeg split operation failed.']);
}

class CompressionException implements Exception {
  final String message;
  const CompressionException([this.message = 'FFmpeg compression operation failed.']);
}

class MetadataException implements Exception {
  final String message;
  const MetadataException([this.message = 'Could not read or write metadata.']);
}
