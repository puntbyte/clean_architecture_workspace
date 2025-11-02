// example/lib/features/auth/data/repositories/auth_repository_impl.violations.dart

import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/data/models/user_model.dart';
import 'package:example/features/auth/data/sources/auth_remote_data_source.dart';
import 'package:example/features/auth/domain/contracts/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
class BadDependencyRepositoryImpl implements AuthRepository {
  // VIOLATION: enforce_abstract_data_source_dependency (depends on concrete implementation)
  final DefaultAuthRemoteDataSource dataSource;

  const BadDependencyRepositoryImpl(
    this.dataSource, // <-- LINT ERROR HERE
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class BadMappingRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;

  const BadMappingRepositoryImpl(this.dataSource);

  @override
  // VIOLATION: disallow_model_return_from_repository (must return Entity, not Model)
  FutureEither<UserModel> getUser(int id) async { // <-- LINT ERROR HERE
    // This implementation "forgets" to map the model to an entity.
    return const Right(UserModel(id: '1', name: 'Bad User'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}