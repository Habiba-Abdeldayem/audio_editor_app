import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/audio_metadata.dart';
import '../repositories/audio_repository.dart';

class UpdateAudioMetadata implements UseCase<Unit, UpdateAudioMetadataParams> {
  final AudioRepository repository;
  const UpdateAudioMetadata(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateAudioMetadataParams params) {
    return repository.writeMetadata(
      filePath: params.filePath,
      metadata: params.metadata,
    );
  }
}

class UpdateAudioMetadataParams extends Equatable {
  final String filePath;
  final AudioMetadata metadata;
  const UpdateAudioMetadataParams(
      {required this.filePath, required this.metadata});
  @override
  List<Object?> get props => [filePath, metadata];
}
