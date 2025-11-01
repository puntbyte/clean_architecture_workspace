import 'package:clean_architecture_core/src/error/failure.dart';
import 'package:fpdart/fpdart.dart';

/// A type definition for a [Future] that returns either a [Failure] or a [ReturnType].
///
/// This is a convenient shorthand for functions that will return either a [Failure] or a
/// successful [ReturnType] in the future.
typedef FutureEither<ReturnType> = Future<Either<Failure, ReturnType>>;
