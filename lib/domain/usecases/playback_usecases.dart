import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/audio_repository.dart';

/// Small, single-purpose playback use cases. Kept in one file since each
/// is a couple of lines — splitting them into five files would add
/// navigation overhead without adding clarity.

class PreparePlayback implements UseCase<Unit, String> {
  final AudioRepository repository;
  const PreparePlayback(this.repository);
  @override
  Future<Either<Failure, Unit>> call(String filePath) =>
      repository.preparePlayback(filePath);
}

class PlayAudio implements UseCase<Unit, NoParams> {
  final AudioRepository repository;
  const PlayAudio(this.repository);
  @override
  Future<Either<Failure, Unit>> call(NoParams params) => repository.play();
}

class PauseAudio implements UseCase<Unit, NoParams> {
  final AudioRepository repository;
  const PauseAudio(this.repository);
  @override
  Future<Either<Failure, Unit>> call(NoParams params) => repository.pause();
}

class SeekAudio implements UseCase<Unit, Duration> {
  final AudioRepository repository;
  const SeekAudio(this.repository);
  @override
  Future<Either<Failure, Unit>> call(Duration position) =>
      repository.seek(position);
}

/// Stream-returning use cases don't fit the Either<Failure,T> UseCase
/// shape (a stream can emit errors on its own), so these are simple
/// callables the bloc subscribes to directly.
class WatchPosition {
  final AudioRepository repository;
  const WatchPosition(this.repository);
  Stream<Duration> call() => repository.positionStream;
}

class WatchPlayingState {
  final AudioRepository repository;
  const WatchPlayingState(this.repository);
  Stream<bool> call() => repository.playingStream;
}
