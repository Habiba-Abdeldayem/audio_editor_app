// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TafsirEditor';

  @override
  String get audioEditorAppBarTitle => 'Audio Editor';

  @override
  String get chooseM4aFile => 'Choose an .m4a file';

  @override
  String get loadingAudio => 'Loading audio...';

  @override
  String get readingFileInfo => 'Reading file info...';

  @override
  String get generatingWaveform => 'Generating waveform...';

  @override
  String get preparingPlayback => 'Preparing playback...';

  @override
  String get compress => 'Compress';

  @override
  String get metadata => 'Metadata';

  @override
  String get chooseDifferentFile => 'Choose a different file';

  @override
  String get compressAudio => 'Compress audio';

  @override
  String currentSize(String size) {
    return 'Current size: $size';
  }

  @override
  String get compressing => 'Compressing…';

  @override
  String get compressionComplete => 'Compression complete';

  @override
  String get compressionFailed => 'Compression failed.';

  @override
  String get chooseSizeToRetry => 'Choose a size below to try again.';

  @override
  String get smaller => 'smaller';

  @override
  String get editMetadata => 'Edit metadata';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldArtist => 'Artist';

  @override
  String get fieldAlbum => 'Album';

  @override
  String get fieldGenre => 'Genre';

  @override
  String get saveMetadata => 'Save metadata';

  @override
  String get split => 'Split';

  @override
  String splitDescription(int minute, int seconds, String duration) {
    return 'Splits into two files at the current playhead — minute $minute, ${seconds}s ($duration).';
  }

  @override
  String get splitAtCurrentPosition => 'Split at current position';

  @override
  String get splitting => 'Splitting...';

  @override
  String get createdFiles => 'Created files';

  @override
  String get fileNoLongerExists => 'File no longer exists.';

  @override
  String couldNotShareFile(String error) {
    return 'Could not share file: $error';
  }

  @override
  String get rename => 'Rename';

  @override
  String get fileName => 'File name';

  @override
  String get cancel => 'Cancel';

  @override
  String renamedTo(String name) {
    return 'Renamed to \"$name\"';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Could not open folder: $error';
  }

  @override
  String get showInFolder => 'Show in folder';

  @override
  String get share => 'Share';

  @override
  String get back10s => 'Back 10s';

  @override
  String get forward10s => 'Forward 10s';

  @override
  String get fileAccessError => 'Could not access the audio file.';

  @override
  String get unsupportedFormatError => 'Only .m4a files are supported.';

  @override
  String get playbackError => 'Playback failed.';

  @override
  String get splitError => 'Could not split the audio file.';

  @override
  String get compressionError => 'Could not compress the audio file.';

  @override
  String get metadataError => 'Could not read or write metadata.';

  @override
  String get validationError => 'Validation failed.';

  @override
  String get unknownError => 'Something went wrong.';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get systemDefault => 'System default';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';
}
