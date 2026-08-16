import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/audio_repository.dart';

class RenameAudioFile implements UseCase<String, RenameAudioFileParams> {
  final AudioRepository repository;
  const RenameAudioFile(this.repository);

  @override
  Future<Either<Failure, String>> call(RenameAudioFileParams params) {
    return repository.renameFile(
      filePath: params.filePath,
      newName: params.newName,
    );
  }
}

class RenameAudioFileParams extends Equatable {
  final String filePath;
  final String newName;
  const RenameAudioFileParams(
      {required this.filePath, required this.newName});
  @override
  List<Object?> get props => [filePath, newName];
}
