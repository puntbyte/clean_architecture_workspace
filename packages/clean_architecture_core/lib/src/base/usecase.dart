import 'package:clean_architecture_core/clean_architecture_core.dart';

/// {@template use_case}
/// An abstract interface class that holds a [Repository].
///
/// This is a base class for all use cases. It ensures that all use cases have a repository, which
/// is responsible for providing data.
/// {@endtemplate}
abstract interface class Usecase {
  /// The repository for this use case.
  final Repository repository;

  /// {@macro use_case}
  const Usecase(this.repository);
}

/// {@template nullary_use_case}
/// An abstract interface class for a use case that takes no parameters.
/// {@endtemplate}
abstract interface class NullaryUsecase<ReturnType> extends Usecase {
  /// {@macro nullary_use_case}
  const NullaryUsecase(super.repository);

  /// Executes the use case.
  FutureEither<ReturnType> call();
}

/// {@template unary_use_case}
/// An abstract interface class for a use case that takes one parameter.
/// {@endtemplate}
abstract interface class UnaryUsecase<ReturnType, ParameterType> extends Usecase {
  /// {@macro unary_use_case}
  const UnaryUsecase(super.repository);

  /// Executes the use case.
  FutureEither<ReturnType> call(ParameterType parameter);
}
