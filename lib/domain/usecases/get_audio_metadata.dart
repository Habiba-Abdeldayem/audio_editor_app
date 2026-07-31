import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/audio_metadata.dart';
import '../repositories/audio_repository.dart';

class GetAudioMetadata implements UseCase<AudioMetadata, GetAudioMetadataParams> {
  final AudioRepository repository;
  const GetAudioMetadata(this.repository);

  @override
  Future<Either<Failure, AudioMetadata>> call(GetAudioMetadataParams params) {
    return repository.readMetadata(params.filePath);
  }
}

class GetAudioMetadataParams extends Equatable {
  final String filePath;
  const GetAudioMetadataParams(this.filePath);
  @override
  List<Object?> get props => [filePath];
}
