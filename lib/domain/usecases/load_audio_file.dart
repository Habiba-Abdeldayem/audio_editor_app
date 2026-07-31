import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/audio_track.dart';
import '../repositories/audio_repository.dart';

class LoadAudioFile implements UseCase<AudioTrack, LoadAudioFileParams> {
  final AudioRepository repository;
  const LoadAudioFile(this.repository);

  @override
  Future<Either<Failure, AudioTrack>> call(LoadAudioFileParams params) {
    return repository.loadAudioFile(params.filePath);
  }
}

class LoadAudioFileParams extends Equatable {
  final String filePath;
  const LoadAudioFileParams(this.filePath);
  @override
  List<Object?> get props => [filePath];
}
