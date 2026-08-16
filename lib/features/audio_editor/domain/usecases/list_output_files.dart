import 'package:audio_editor_app/features/audio_editor/domain/repositories/audio_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/audio_local_data_source.dart' show OutputFileInfo;


class ListOutputFiles extends UseCase<List<OutputFileInfo>, String> {
  final AudioRepository repository;

  ListOutputFiles(this.repository);

  @override
  Future<Either<Failure, List<OutputFileInfo>>> call(String folderName) {
    return repository.listOutputFiles(folderName);
  }
}
