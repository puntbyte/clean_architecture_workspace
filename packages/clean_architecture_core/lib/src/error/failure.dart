/// {@template failure}
/// A simple class to represent a failure in a use case.
///
/// This is a base class that can be extended to create more specific failure types. For example:
///
/// ```dart
/// class ServerFailure extends Failure {
///  const ServerFailure({required this.message});
///
///  final String message;
/// }
/// ```
/// {@endtemplate}
abstract interface class Failure {
  /// {@macro failure}
  const Failure();
}
