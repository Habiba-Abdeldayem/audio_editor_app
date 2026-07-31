import '../../domain/entities/audio_metadata.dart';

class AudioMetadataModel extends AudioMetadata {
  const AudioMetadataModel({
    super.title,
    super.artist,
    super.album,
    super.genre,
    super.artwork,
  });

  factory AudioMetadataModel.fromEntity(AudioMetadata m) => AudioMetadataModel(
        title: m.title,
        artist: m.artist,
        album: m.album,
        genre: m.genre,
        artwork: m.artwork,
      );
}
