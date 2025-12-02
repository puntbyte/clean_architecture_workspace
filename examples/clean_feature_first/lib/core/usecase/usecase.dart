// lib/core/usecase/usecase.dart

import 'package:clean_feature_first/core/utils/types.dart';

/// Base interface for Use Cases.
abstract interface class Usecase {}

/// Base interface for Use Cases with no parameters.
abstract interface class NullaryUsecase<ReturnType> extends Usecase {
  FutureEither<ReturnType> call();
}

/// Base interface for Use Cases with a single parameter.
abstract interface class UnaryUsecase<ReturnType, ParameterType> extends Usecase {
  FutureEither<ReturnType> call(ParameterType parameter);
}
