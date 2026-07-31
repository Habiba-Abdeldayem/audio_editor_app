import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/audio_repository.dart';

/// Splits the currently loaded file into two halves at the given point
/// (the "current minute" the playhead is on).
class SplitAudioFile implements UseCase<List<String>, SplitAudioFileParams> {
  final AudioRepository repository;
  const SplitAudioFile(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(SplitAudioFileParams params) {
    return repository.splitAudio(
      filePath: params.filePath,
      splitPoint: params.splitPoint,
    );
  }
}

class SplitAudioFileParams extends Equatable {
  final String filePath;
  final Duration splitPoint;
  const SplitAudioFileParams(
      {required this.filePath, required this.splitPoint});
  @override
  List<Object?> get props => [filePath, splitPoint];
}
