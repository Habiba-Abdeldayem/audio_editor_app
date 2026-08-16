import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// The application title shown in the OS task switcher.
  ///
  /// In en, this message translates to:
  /// **'TafsirEditor'**
  String get appTitle;

  /// Title shown in the AppBar.
  ///
  /// In en, this message translates to:
  /// **'Audio Editor'**
  String get audioEditorAppBarTitle;

  /// Button label to pick an audio file.
  ///
  /// In en, this message translates to:
  /// **'Choose an .m4a file'**
  String get chooseM4aFile;

  /// Generic loading message while audio is being prepared.
  ///
  /// In en, this message translates to:
  /// **'Loading audio...'**
  String get loadingAudio;

  /// Loading step: reading file metadata.
  ///
  /// In en, this message translates to:
  /// **'Reading file info...'**
  String get readingFileInfo;

  /// Loading step: generating the waveform visualization.
  ///
  /// In en, this message translates to:
  /// **'Generating waveform...'**
  String get generatingWaveform;

  /// Loading step: preparing the audio player.
  ///
  /// In en, this message translates to:
  /// **'Preparing playback...'**
  String get preparingPlayback;

  /// Button label to open the compression sheet.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get compress;

  /// Button label to open the metadata editor.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadata;

  /// Button label to pick a different audio file.
  ///
  /// In en, this message translates to:
  /// **'Choose a different file'**
  String get chooseDifferentFile;

  /// Title of the compression bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Compress audio'**
  String get compressAudio;

  /// Displays the current file size in the compression sheet.
  ///
  /// In en, this message translates to:
  /// **'Current size: {size}'**
  String currentSize(String size);

  /// Shown while compression is in progress.
  ///
  /// In en, this message translates to:
  /// **'Compressing…'**
  String get compressing;

  /// Shown when compression finishes successfully.
  ///
  /// In en, this message translates to:
  /// **'Compression complete'**
  String get compressionComplete;

  /// Fallback error message when compression fails.
  ///
  /// In en, this message translates to:
  /// **'Compression failed.'**
  String get compressionFailed;

  /// Shown under error to prompt retry.
  ///
  /// In en, this message translates to:
  /// **'Choose a size below to try again.'**
  String get chooseSizeToRetry;

  /// No description provided for @smaller.
  ///
  /// In en, this message translates to:
  /// **'smaller'**
  String get smaller;

  /// Title of the metadata editor bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Edit metadata'**
  String get editMetadata;

  /// Label for the Title text field in the metadata editor.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// Label for the Artist text field in the metadata editor.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get fieldArtist;

  /// Label for the Album text field in the metadata editor.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get fieldAlbum;

  /// Label for the Genre text field in the metadata editor.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get fieldGenre;

  /// Button label to save metadata changes.
  ///
  /// In en, this message translates to:
  /// **'Save metadata'**
  String get saveMetadata;

  /// Section title for the split feature.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// Explains where the split will occur.
  ///
  /// In en, this message translates to:
  /// **'Splits into two files at the current playhead — minute {minute}, {seconds}s ({duration}).'**
  String splitDescription(int minute, int seconds, String duration);

  /// Button label to split the audio at the current playhead.
  ///
  /// In en, this message translates to:
  /// **'Split at current position'**
  String get splitAtCurrentPosition;

  /// Label shown on the split button while splitting is in progress.
  ///
  /// In en, this message translates to:
  /// **'Splitting...'**
  String get splitting;

  /// Label above the list of files created by a split.
  ///
  /// In en, this message translates to:
  /// **'Created files'**
  String get createdFiles;

  /// Snackbar message when a file has been deleted.
  ///
  /// In en, this message translates to:
  /// **'File no longer exists.'**
  String get fileNoLongerExists;

  /// Error snackbar when sharing fails.
  ///
  /// In en, this message translates to:
  /// **'Could not share file: {error}'**
  String couldNotShareFile(String error);

  /// Dialog title and tooltip for renaming a file.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Label for the file name text field in the rename dialog.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileName;

  /// Cancel button label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Snackbar confirming a successful rename.
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"{name}\"'**
  String renamedTo(String name);

  /// Error snackbar when opening folder fails.
  ///
  /// In en, this message translates to:
  /// **'Could not open folder: {error}'**
  String couldNotOpenFolder(String error);

  /// Tooltip for the show-in-folder action icon.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get showInFolder;

  /// Tooltip for the share action icon.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Tooltip for the rewind 10 seconds button.
  ///
  /// In en, this message translates to:
  /// **'Back 10s'**
  String get back10s;

  /// Tooltip for the forward 10 seconds button.
  ///
  /// In en, this message translates to:
  /// **'Forward 10s'**
  String get forward10s;

  /// Error when the audio file cannot be accessed.
  ///
  /// In en, this message translates to:
  /// **'Could not access the audio file.'**
  String get fileAccessError;

  /// Error when an unsupported file format is selected.
  ///
  /// In en, this message translates to:
  /// **'Only .m4a files are supported.'**
  String get unsupportedFormatError;

  /// Error when audio playback fails.
  ///
  /// In en, this message translates to:
  /// **'Playback failed.'**
  String get playbackError;

  /// Error when splitting the audio file fails.
  ///
  /// In en, this message translates to:
  /// **'Could not split the audio file.'**
  String get splitError;

  /// Error when compressing the audio file fails.
  ///
  /// In en, this message translates to:
  /// **'Could not compress the audio file.'**
  String get compressionError;

  /// Error when reading or writing metadata fails.
  ///
  /// In en, this message translates to:
  /// **'Could not read or write metadata.'**
  String get metadataError;

  /// Generic validation error.
  ///
  /// In en, this message translates to:
  /// **'Validation failed.'**
  String get validationError;

  /// Fallback error message for unexpected failures.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get unknownError;

  /// Title of the settings bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Section header for theme selection.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Theme option that follows the OS setting.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// Light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Section header for language selection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
