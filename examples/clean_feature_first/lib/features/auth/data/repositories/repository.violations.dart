// example/lib/features/auth/data/repositories/repository.violations.dart

import 'dart:ui';

import 'package:clean_feature_first/core/error/exceptions.dart';
import 'package:clean_feature_first/core/error/failures.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/data/models/user_model.dart';
import 'package:clean_feature_first/features/auth/data/sources/auth_source.dart';
import 'package:clean_feature_first/features/auth/data/sources/default_auth_source.dart';
import 'package:clean_feature_first/features/auth/domain/entities/user.dart';
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';
import 'package:fpdart/fpdart.dart';

// LINT: [1] enforce_layer_independence
// REASON: Data layer should not import Presentation layer.
import 'package:clean_feature_first/features/auth/presentation/pages/home_page.dart'; // <-- LINT WARNING HERE

// LINT: [2] enforce_annotations (Required)
// REASON: Repositories must be annotated with `@LazySingleton` or `@Singleton`.

// LINT: [3] enforce_naming_pattern
// REASON: Name `AuthService` does not match pattern `{{kind}}{{name}}Repository`.
class AuthService implements AuthPort { // <-- LINT WARNING HERE (Missing Annotation & Bad Name)

  // LINT: [4] enforce_abstract_data_source_dependency
  // REASON: Must depend on `AuthSource` (Interface), not `Default...` (Concrete).
  final DefaultAuthSource concreteSource; // <-- LINT WARNING HERE

  // LINT: [5] disallow_dependency_instantiation
  // REASON: Dependencies must be injected, not created internally.
  final _internalSource = DefaultAuthSource(); // <-- LINT WARNING HERE

  AuthService(this.concreteSource);

  @override
  FutureEither<UserModel> login(String u, String p) async {
    // LINT: [6] enforce_try_catch_in_repository
    // REASON: Calls to DataSources must be wrapped in a `try` block.
    final model = await concreteSource.getUser(u); // <-- LINT WARNING HERE

    // LINT: [7] disallow_model_return_from_repository
    // REASON: Repositories must return Entities (Domain), not Models (Data).
    return Right(model); // <-- LINT WARNING HERE
  }

  @override
  FutureEither<void> logout() => throw UnimplementedError();

}

// LINT: [8] enforce_repository_contract
// REASON: Repositories must implement a Domain Port (Interface).
// ignore: enforce_annotations
class RogueRepository { // <-- LINT WARNING HERE
  void doSomething() {}
}

// ignore: enforce_annotations
class BadErrorHandlingRepository implements AuthPort {
  final AuthSource _source;

  const BadErrorHandlingRepository(this._source);

  @override
  FutureEither<User> login(String username, String password) async {
    try {
      final user = await _source.getUser(username);
      return Right(user.toEntity());
    } on ServerException {
      // LINT: [9] convert_exceptions_to_failures
      // REASON: Config requires `ServerException` to map to `ServerFailure`.
      // Returning `CacheFailure` here is a violation of the mapping rules.
      return const Left(CacheFailure()); // <-- LINT WARNING HERE
    } catch (e) {
      // LINT: [10] disallow_throwing_from_repository
      // REASON: Repositories act as boundaries; they must return Failures, not throw.
      throw Exception('Uncaught'); // <-- LINT WARNING HERE

      // LINT: [10] disallow_throwing_from_repository
      // REASON: Rethrowing is also forbidden by the 'boundary' error handler rule.
      rethrow; // <-- LINT WARNING HERE
    }
  }

  // Lint: arch_exception_missing
  @override
  FutureEither<void> logout() => throw UnimplementedError();
}