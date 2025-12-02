// example/lib/features/auth/data/repositories/auth_repository.dart

import 'package:clean_feature_first/core/error/exceptions.dart';
import 'package:clean_feature_first/core/error/failures.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/data/sources/auth_source.dart';
import 'package:clean_feature_first/features/auth/data/sources/default_auth_source.dart';
import 'package:clean_feature_first/features/auth/domain/entities/user.dart';
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

// CORRECT:
// 1. Naming: Matches `{{kind}}{{name}}Repository` (DefaultAuthRepository).
// 2. Inheritance: Implements the Domain Port (`AuthPort`).
// 3. Annotation: Annotated with `@LazySingleton` (as required by config).
@LazySingleton(as: AuthPort)
class DefaultAuthRepository implements AuthPort {
  // CORRECT:
  // 4. Dependency: Depends on the Source Interface (`AuthSource`), not the implementation.
  final AuthSource _source;

  // CORRECT:
  // 5. Injection: Source is injected via constructor.
  const DefaultAuthRepository(this._source);

  @override
  FutureEither<User> login(String username, String password) async {
    // CORRECT:
    // 6. Error Handling: Wrapped in `try/catch` (enforce_try_catch_in_repository).
    try {
      final model = await _source.getUser(username);

      // CORRECT:
      // 7. Mapping: Converts Model to Entity before returning (disallow_model_return...).
      return Right(model.toEntity());
    } on ServerException {
      // CORRECT:
      // 8. Conversion: Maps `ServerException` -> `ServerFailure` (convert_exceptions_to_failures).
      return const Left(ServerFailure());
    } catch (e) {
      // Fallback for unhandled exceptions
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<void> logout() => throw UnimplementedError();
}
