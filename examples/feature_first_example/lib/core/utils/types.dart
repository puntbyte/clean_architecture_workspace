// example/lib/core/utils/types.dart
import 'package:fpdart/fpdart.dart';

/// A class representing a failure in a business logic operation.
class Failure {
  final String message;
  const Failure([this.message = 'An unexpected error occurred.']);
}

/// A typedef for a Future that returns an Either of a Failure or a value of type T.
typedef FutureEither<T> = Future<Either<Failure, T>>;

typedef IntId = int;

typedef StringId = String;
