import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// Every use case returns Either<Failure, T> so the presentation layer
/// always has to explicitly handle the failure path — no thrown exceptions
/// leak past the domain boundary.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// For use cases that take no parameters.
class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
