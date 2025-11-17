// example/lib/core/usecase/usecase.dart
import 'package:example/core/utils/types.dart';

/// A base class for use cases.
abstract interface class Usecase {}

abstract interface class UnaryUsecase<ReturnType, ParameterType> extends Usecase {
  FutureEither<ReturnType> call(ParameterType parameter);
}

abstract interface class NullaryUsecase<ReturnType> extends Usecase {
  FutureEither<ReturnType> call();
}
