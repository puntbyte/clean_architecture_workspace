// example/lib/core/error/failures.dart

/// The base class for all failures.
/// Failures are Value Objects that correspond to logical errors in the domain.
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// Represents a failure caused by the server.
/// Note: We don't usually pass the raw status code here unless it's relevant
/// to the business logic (e.g. "401" -> "User needs to login").
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Failure']);
}

/// Represents a failure to load or save data locally.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Failure']);
}
