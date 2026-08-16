import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
/// The presentation layer only ever knows about [Failure]s — never about
/// the raw exceptions/plugins thrown by the data layer.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class FileAccessFailure extends Failure {
  const FileAccessFailure([super.message = 'Could not access the audio file.']);
}

class UnsupportedFormatFailure extends Failure {
  const UnsupportedFormatFailure(
      [super.message = 'Only .m4a files are supported.']);
}

class PlaybackFailure extends Failure {
  const PlaybackFailure([super.message = 'Playback failed.']);
}

class SplitFailure extends Failure {
  const SplitFailure([super.message = 'Could not split the audio file.']);
}

class CompressionFailure extends Failure {
  const CompressionFailure(
      [super.message = 'Could not compress the audio file.']);
}

class MetadataFailure extends Failure {
  const MetadataFailure([super.message = 'Could not read or write metadata.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
