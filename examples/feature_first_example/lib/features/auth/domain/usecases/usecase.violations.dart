// lib/features/auth/domain/usecases/usecase.violations.dart

import 'package:feature_first_example/core/usecase/usecase.dart';
import 'package:feature_first_example/core/utils/types.dart';
import 'package:feature_first_example/features/auth/data/sources/default_auth_source.dart';

// LINT: [1] disallow_flutter_in_domain
// REASON: Domain layer must be platform-agnostic (no UI types).
import 'package:flutter/material.dart'; //! <-- LINT WARNING

// LINT: [2] enforce_layer_independence
// REASON: Domain layer cannot import from the Data layer.
import 'package:feature_first_example/features/auth/data/models/user_model.dart'; //! <-- LINT WARNING

// LINT: [3] enforce_abstract_repository_dependency
// REASON: Domain must depend on Interfaces (Ports), not Concrete Implementations.
import 'package:feature_first_example/features/auth/data/repositories/auth_repository.dart'; //! <-- LINT WARNING

// LINT: [4] disallow_service_locator
// REASON: Service Locators hide dependencies; use Constructor Injection.
import 'package:get_it/get_it.dart'; //! <-- LINT WARNING

import 'package:injectable/injectable.dart';

// LINT: [5] enforce_semantic_naming
// REASON: Grammar violation. UseCases must be `VerbNoun` (e.g., `LoginUser`), not `NounVerb` (`UserLogin`).
// ignore: enforce_annotations, enforce_usecase_contract
class UserLogin { //! <-- LINT WARNING
  const UserLogin();
}

// LINT: [6] enforce_naming_antipattern
// REASON: Name uses forbidden suffix `UseCase`. Pattern should be `{{name}}` (e.g. `GetProfile`).
// ignore: enforce_annotations, enforce_usecase_contract
class GetProfileUseCase { //! <-- LINT WARNING
  const GetProfileUseCase();
}

// LINT: [7] enforce_annotations (Required)
// REASON: UseCases must be annotated with `@Injectable`.
// ignore: enforce_usecase_contract
class LogoutUser { //! <-- LINT WARNING
  void call() {}
}

// LINT: [8] enforce_usecase_contract
// REASON: UseCases must implement/extend `UnaryUsecase` or `NullaryUsecase`.
// ignore: enforce_annotations
class LoginUser { //! <-- LINT WARNING
  void call() {}
}

@injectable
class GetUser implements UnaryUsecase<dynamic, int> {
  // LINT: [9] enforce_abstract_repository_dependency
  // REASON: Dependency is a concrete class `DefaultAuthRepository`. Use the interface.
  final DefaultAuthRepository repo; //! <-- LINT WARNING

  GetUser(this.repo);

  void antiPatterns() {
    // LINT: [10] disallow_dependency_instantiation
    // REASON: Dependencies must be injected, not created inside the class.
    final localRepo = DefaultAuthRepository(DefaultAuthSource()); //! <-- LINT WARNING

    // LINT: [11] disallow_service_locator
    // REASON: Do not use `getIt` inside business logic.
    // ignore: enforce_abstract_repository_dependency
    final loc = GetIt.I.get<DefaultAuthRepository>(); //! <-- LINT WARNING
  }

  // LINT: [12] enforce_type_safety
  // REASON: Parameter named `id` must be `IntId`, not primitive `int`.
  @override
  FutureEither<dynamic> call(int id) async => throw UnimplementedError(); //! <-- LINT WARNING
}

// ignore: enforce_annotations
class BadTypes implements NullaryUsecase<void> {
  // LINT: [13] enforce_type_safety
  // REASON: Return type must be `FutureEither`, not raw `Future`.
  @override
  FutureEither<void> call() async => throw UnimplementedError(); //! <-- LINT WARNING

  // LINT: [14] disallow_model_in_domain
  // REASON: UseCases cannot return Data Models. Use Entities.
  FutureEither<UserModel> unsafeCall() async { //! <-- LINT WARNING
    throw UnimplementedError();
  }
}

// LINT: [15] disallow_flutter_in_domain
// REASON: Domain layer must be platform-agnostic (no UI types).
// ignore: enforce_annotations
class FetchColor implements NullaryUsecase<Color> { //! <-- LINT WARNING
  @override
  FutureEither<Color> call() { //! <-- LINT WARNING
    return Future.value.call();
  }
}

// LINT: [16] enforce_file_and_folder_location
// REASON: This is a Repository Implementation (Data Layer), incorrectly placed in the UseCases folder.
// ignore: enforce_annotations, enforce_usecase_contract
class AuthRepositoryImpl { //! <-- LINT WARNING
  const AuthRepositoryImpl();
}