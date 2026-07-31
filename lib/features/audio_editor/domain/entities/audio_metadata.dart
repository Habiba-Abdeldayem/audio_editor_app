import 'package:equatable/equatable.dart';

/// Editable tag data for an m4a file (MP4 "moov/udta/meta" atoms under the
/// hood, abstracted away by the data layer).
class AudioMetadata extends Equatable {
  final String title;
  final String artist;
  final String album;
  final String genre;

  /// Raw artwork image bytes (jpeg/png) or null if no embedded artwork.
  final List<int>? artwork;

  const AudioMetadata({
    this.title = '',
    this.artist = '',
    this.album = '',
    this.genre = '',
    this.artwork,
  });

  AudioMetadata copyWith({
    String? title,
    String? artist,
    String? album,
    String? genre,
    List<int>? artwork,
    bool clearArtwork = false,
  }) {
    return AudioMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      artwork: clearArtwork ? null : (artwork ?? this.artwork),
    );
  }

  @override
  List<Object?> get props => [title, artist, album, genre, artwork];
}
