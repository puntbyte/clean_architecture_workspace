// lib/features/auth/data/repositories/auth_repository_impl.violations.dart

import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/data/models/user_model.dart';
import 'package:example/features/auth/data/sources/auth_remote_data_source.dart';
import 'package:example/features/auth/domain/contracts/auth_port.dart';
import 'package:fpdart/fpdart.dart';


// LINT: enforce_repository_implementation_contract
// Reason: Must implement a Domain Port.
class RogueRepository {
}

class BadRepoImpl implements AuthRepository {
  // LINT: disallow_dependency_instantiation
  // Reason: Dependencies must be injected, not created.
  final _source = DefaultAuthRemoteDataSource();

  // LINT: enforce_abstract_data_source_dependency
  // Reason: Depend on `AuthRemoteDataSource` (Interface), not `Default...` (Impl).
  final DefaultAuthRemoteDataSource _concreteSource;

  BadRepoImpl(this._concreteSource);

  @override
  // LINT: disallow_model_return_from_repository
  // Reason: Returns UserModel (Data) instead of User (Domain).
  FutureEither<UserModel> login(String u, String p) async {

    // LINT: disallow_throwing_from_repository
    // Reason: Repos must capture errors, not throw them.
    throw Exception('Boom');

    // LINT: enforce_try_catch_in_repository
    // Reason: Call to source is unsafe without try/catch.
    return Right(await _concreteSource.login(u, p));
  }

  // LINT: disallow_public_members_in_implementation
  // Reason: Implementation details should be private.
  void helperMethod() {}

  @override
  FutureEither<void> logout() async => const Right(null);
}

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
    return const Right(UserModel(id: '1', names: 'Bad User'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}