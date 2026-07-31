# Audio Editor (Flutter, Clean Architecture)

An m4a audio editor: waveform navigation + playback, split-in-half at the
current playhead, compression with size-before/after preview, and metadata
(title/artist/album/genre + artwork) editing.

## Architecture

```
lib/
  core/            # Shared, framework-light building blocks. No feature
                    # logic lives here — only things every layer can depend on.
    error/          Failure (domain-facing) + Exception (data-facing) types
    usecases/       UseCase<Type, Params> base class, NoParams
    di/             GetIt wiring: datasource -> repository -> usecases -> bloc
    utils/          Formatters (duration, file size, size estimation)
    theme/          AppTheme
    constants/      AppConstants (bitrate presets, etc.)

  domain/          # Pure Dart. No Flutter, no plugin imports. This is the
                    # part of the app that defines *what* it does.
    entities/       AudioTrack, AudioMetadata, CompressionOption
    repositories/   AudioRepository — the abstract contract
    usecases/       One class per user action (LoadAudioFile, SplitAudioFile,
                    CompressAudioFile, GetCompressionOptions,
                    GetAudioMetadata, UpdateAudioMetadata, plus the small
                    playback_usecases.dart: PreparePlayback/Play/Pause/Seek/
                    WatchPosition/WatchPlayingState)

  data/            # Implements the domain contract using real plugins.
    models/         AudioTrackModel, AudioMetadataModel (extend the entities)
    datasources/    AudioLocalDataSource — the only file that imports
                    just_audio, ffmpeg_kit, audiotags, audio_waveforms
    repositories/   AudioRepositoryImpl — maps plugin exceptions to Failures

  presentation/    # Flutter/UI + state management.
    bloc/           AudioEditorBloc, events, state (flutter_bloc)
    pages/          AudioEditorPage — the single editor screen
    widgets/        WaveformPlayer, PlaybackControls, SplitSection,
                    CompressSheet, MetadataEditorSheet
```

Dependency direction is strictly inward: `presentation -> domain <- data`,
wired together only in `core/di/injection_container.dart`. The domain layer
has zero knowledge of just_audio/ffmpeg/audiotags — swapping any of those
plugins only touches `data/`.

## How each feature is implemented

- **Load + display + navigate**: `AudioLocalDataSource.loadAudioFile` probes
  duration via `just_audio` and extracts ~400 downsampled amplitude samples
  via `audio_waveforms`' `PlayerController.extractWaveformData`, cached once
  on the `AudioTrack` entity. `WaveformPlayer` is a custom `CustomPainter` +
  `GestureDetector` — dragging anywhere emits a seek on every pointer-move
  event (optimistic UI update), debounced 40ms before it hits the actual
  player, which is what makes scrubbing feel smooth instead of stepping.

- **Split**: `FFmpeg -c copy` (stream copy, no re-encode) run twice — once
  `-ss 0 -to <point>` and once `-ss <point>` to the end — so splitting is
  fast and lossless. Triggered by `SplitSection`'s button, which always
  splits at `state.position` (the current playhead / "current minute").

- **Compress**: `GetCompressionOptions` computes *estimated* output size per
  bitrate preset (`bitrate * duration / 8`) without touching ffmpeg, so
  `CompressSheet` can show "128 kbps — 6.1 MB → ~2.4 MB" instantly. Only on
  confirmation does `CompressAudioFile` actually invoke
  `ffmpeg -c:a aac -b:a <bitrate>k`.

- **Metadata**: `audiotags` reads/writes MP4 tag atoms (title, artist,
  album, genre, cover art) directly on the m4a container.
  `MetadataEditorSheet` lets the user edit fields and pick new artwork via
  `image_picker`.

## Setup

This project was authored outside a Flutter SDK environment (no network
access to pub.dev here), so `pubspec.lock` isn't included and packages
haven't been fetched. To run it:

```bash
flutter pub get
```

### Platform notes

- **Android**: `ffmpeg_kit_flutter_new` needs `minSdkVersion 24+` in
  `android/app/build.gradle`. `file_picker`/`image_picker` need the usual
  storage/media `<uses-permission>` entries — recent versions of these
  plugins add them via manifest merge automatically, but double-check after
  `flutter pub get`.
- **iOS**: add `NSPhotoLibraryUsageDescription` to `Info.plist` for artwork
  picking, and `NSAppleMusicUsageDescription` if you extend file picking to
  the media library.
- `ffmpeg_kit_flutter_new` ships prebuilt binaries per platform — no extra
  native setup needed beyond the plugin itself.

### Known follow-ups (intentionally left out to keep this a clean starting
point rather than a finished commercial app)

- No undo/redo or "revert to original" flow after split/compress.
- Split always produces two halves at the playhead; a UI for splitting into
  N parts would extend `SplitAudioFile`/`SplitSection` rather than replace
  them.
- No background-audio/lock-screen controls (`just_audio_background` would
  be the natural addition).
- No automated tests included; `bloc_test`/`mocktail` are already in
  `pubspec.yaml` dev_dependencies to make adding them straightforward
  (mock `AudioRepository`, test each use case and the bloc's event→state
  transitions in isolation).
