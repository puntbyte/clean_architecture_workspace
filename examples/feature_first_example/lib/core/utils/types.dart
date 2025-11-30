// lib/core/utils/types.dart
import 'package:feature_first_example/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// Standard wrapper for async operations.
typedef FutureEither<T> = Future<Either<Failure, T>>;

typedef StreamEither<T> = Stream<Either<Failure, T>>;

/// Strong types for IDs to avoid primitive obsession.
typedef IntId = int;
typedef StringId = String;
