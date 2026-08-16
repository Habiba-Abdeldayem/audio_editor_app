import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_store_plus/media_store_plus.dart';

import '../../features/audio_editor/data/datasources/audio_local_data_source.dart';
import '../../features/audio_editor/data/repositories/audio_repository_impl.dart';
import '../../features/audio_editor/domain/repositories/audio_repository.dart';
import '../../features/audio_editor/domain/usecases/compress_audio_file.dart';
import '../../features/audio_editor/domain/usecases/get_audio_metadata.dart';
import '../../features/audio_editor/domain/usecases/get_compression_options.dart';
import '../../features/audio_editor/domain/usecases/load_audio_file.dart';
import '../../features/audio_editor/domain/usecases/playback_usecases.dart';
import '../../features/audio_editor/domain/usecases/split_audio_file.dart';
import '../../features/audio_editor/domain/usecases/update_audio_metadata.dart';
import '../../features/audio_editor/presentation/bloc/audio_editor_cubit.dart';

final sl = GetIt.instance;

/// Wires the dependency graph once at app startup:
/// datasource -> repository -> use cases -> bloc.
/// Each layer only ever depends on the abstraction of the layer below it.
Future<void> initDependencies() async {
  // External / platform
  await MediaStore.ensureInitialized();
  sl.registerLazySingleton<AudioPlayer>(() => AudioPlayer());

  // Data
  sl.registerLazySingleton<AudioLocalDataSource>(
    () => AudioLocalDataSourceImpl(player: sl()),
  );
  sl.registerLazySingleton<AudioRepository>(
    () => AudioRepositoryImpl(sl()),
  );

  // Domain use cases
  sl.registerFactory(() => LoadAudioFile(sl()));
  sl.registerFactory(() => SplitAudioFile(sl()));
  sl.registerFactory(() => GetCompressionOptions(sl()));
  sl.registerFactory(() => CompressAudioFile(sl()));
  sl.registerFactory(() => GetAudioMetadata(sl()));
  sl.registerFactory(() => UpdateAudioMetadata(sl()));
  sl.registerFactory(() => PreparePlayback(sl()));
  sl.registerFactory(() => PlayAudio(sl()));
  sl.registerFactory(() => PauseAudio(sl()));
  sl.registerFactory(() => SeekAudio(sl()));
  sl.registerFactory(() => WatchPosition(sl()));
  sl.registerFactory(() => WatchPlayingState(sl()));

  // Presentation
  sl.registerFactory(
    () => AudioEditorCubit(
      loadAudioFile: sl(),
      splitAudioFile: sl(),
      getCompressionOptions: sl(),
      compressAudioFile: sl(),
      getAudioMetadata: sl(),
      updateAudioMetadata: sl(),
      preparePlayback: sl(),
      playAudio: sl(),
      pauseAudio: sl(),
      seekAudio: sl(),
      watchPosition: sl(),
      watchPlayingState: sl(),
    ),
  );
}
