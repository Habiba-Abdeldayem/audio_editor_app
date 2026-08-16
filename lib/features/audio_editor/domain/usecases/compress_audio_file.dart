import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/audio_repository.dart';

class CompressAudioFile implements UseCase<String, CompressAudioFileParams> {
  final AudioRepository repository;
  const CompressAudioFile(this.repository);

  @override
  Future<Either<Failure, String>> call(CompressAudioFileParams params) {
    return repository.compressAudio(
      filePath: params.filePath,
      bitrateKbps: params.bitrateKbps,
      onProgress: params.onProgress,
    );
  }
}

class CompressAudioFileParams extends Equatable {
  final String filePath;
  final int bitrateKbps;
  final void Function(double progress)? onProgress;
  const CompressAudioFileParams({
    required this.filePath,
    required this.bitrateKbps,
    this.onProgress,
  });
  @override
  List<Object?> get props => [filePath, bitrateKbps];
}
