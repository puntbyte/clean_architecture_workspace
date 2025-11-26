// example/lib/core/error/exceptions.dart

/// The base class for all application-specific exceptions.
/// Data Sources should throw subclasses of this or standard Dart Exceptions.
abstract class CustomException implements Exception {
  final String? message;
  const CustomException([this.message]);
}

/// Thrown when an interaction with a remote server (API) fails.
class ServerException extends CustomException {
  final int? statusCode;
  const ServerException({this.statusCode, String? message}) : super(message);
}

/// Thrown when a local cache (DB/SharedPreferences) operation fails.
class CacheException extends CustomException {
  const CacheException([super.message]);
}
