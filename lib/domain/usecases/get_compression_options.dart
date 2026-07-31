import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/compression_option.dart';
import '../repositories/audio_repository.dart';

/// Returns presets with sizes estimated *before* any encoding happens, so
/// the compression sheet can show "before vs after" instantly.
class GetCompressionOptions
    implements UseCase<List<CompressionOption>, GetCompressionOptionsParams> {
  final AudioRepository repository;
  const GetCompressionOptions(this.repository);

  @override
  Future<Either<Failure, List<CompressionOption>>> call(
    GetCompressionOptionsParams params,
  ) {
    return repository.getCompressionOptions(params.filePath);
  }
}

class GetCompressionOptionsParams extends Equatable {
  final String filePath;
  const GetCompressionOptionsParams(this.filePath);
  @override
  List<Object?> get props => [filePath];
}
