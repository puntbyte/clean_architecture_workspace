// lib/features/auth/domain/usecases/usecase.violations.dart

import 'package:clean_feature_first/core/usecase/usecase.dart';
import 'package:clean_feature_first/core/utils/types.dart';

// Lint: [1] arch_dep_component
// Reason: Domain layer cannot import from the Data layer.
import 'package:clean_feature_first/features/auth/data/models/user_model.dart'; //! <-- LINT WARNING

// Lint: [2] arch_dep_component
// Reason: Domain must depend on Interfaces (Ports), not Concrete Implementations.
import 'package:clean_feature_first/features/auth/data/repositories/auth_repository.dart'; //! <-- LINT WARNING

// Lint: [3]: arch_dep_component
// Reason: Domain layer cannot import from the Data layer.
import 'package:clean_feature_first/features/auth/data/sources/default_auth_source.dart'; //! <-- LINT WARNING

// Lint: [4*] disallow_service_locator
// Reason: Service Locators hide dependencies; use Constructor Injection.
import 'package:get_it/get_it.dart'; //! <-- LINT WARNING

import 'package:injectable/injectable.dart';

// LINT: [5] arch_dep_external
// Reason: Domain layer must be platform-agnostic (no UI types).
import 'package:flutter/material.dart'; //! <-- LINT WARNING

// LINT: [5] arch_naming_grammar
// Reason: Grammar violation. UseCases must be `VerbNoun` (e.g., `LoginUser`), not `NounVerb` (`UserLogin`).
@injectable
class UserLogin { //! <-- LINT WARNING
  const UserLogin();
}

// LINT: [6] enforce_naming_antipattern
// Reason: Name uses forbidden suffix `UseCase`. Pattern should be `{{name}}` (e.g. `GetProfile`).
@injectable
class GetProfileUseCase { //! <-- LINT WARNING
  const GetProfileUseCase();
}

// LINT: [7] arch_annot_missing (Required)
// Reason: UseCases must be annotated with `@Injectable`.
// ignore: arch_type_missing_base, arch_naming_grammar
class LogoutUser { //! <-- LINT WARNING
  void call() {}
}

// LINT: [8] enforce_usecase_contract
// Reason: UseCases must implement/extend `UnaryUsecase` or `NullaryUsecase`.
@injectable
// ignore: arch_naming_grammar, arch_type_missing_base
class LoginUser { //! <-- LINT WARNING
  void call() {}
}

@Injectable()
class GetUser implements UnaryUsecase<dynamic, int> {
  // LINT: [9] enforce_abstract_repository_dependency
  // Reason: Dependency is a concrete class `DefaultAuthRepository`. Use the interface.
  final DefaultAuthRepository repo; //! <-- LINT WARNING

  GetUser(this.repo);

  void antiPatterns() {
    // LINT: [10] disallow_dependency_instantiation
    // Reason: Dependencies must be injected, not created inside the class.
    final localRepo = DefaultAuthRepository(DefaultAuthSource()); //! <-- LINT WARNING

    // LINT: [11] disallow_service_locator
    // Reason: Do not use `getIt` inside business logic.
    // ignore: enforce_abstract_repository_dependency
    final loc = GetIt.I.get<DefaultAuthRepository>(); //! <-- LINT WARNING
  }

  // LINT: [12] enforce_type_safety
  // Reason: Parameter named `id` must be `IntId`, not primitive `int`.
  @override
  FutureEither<dynamic> call(int id) async => throw UnimplementedError(); //! <-- LINT WARNING
}

// ignore: arch_annot_missing
class BadTypes implements NullaryUsecase<void> {
  // LINT: [13] enforce_type_safety
  // Reason: Return type must be `FutureEither`, not raw `Future`.
  @override
  FutureEither<void> call() async => throw UnimplementedError(); //! <-- LINT WARNING

  // LINT: [14] disallow_model_in_domain
  // Reason: UseCases cannot return Data Models. Use Entities.
  FutureEither<UserModel> unsafeCall() async { //! <-- LINT WARNING
    throw UnimplementedError();
  }
}

// LINT: [15] disallow_flutter_in_domain
// Reason: Domain layer must be platform-agnostic (no UI types).
// ignore: enforce_annotations
class FetchColor implements NullaryUsecase<Color> { //! <-- LINT WARNING
  @override
  FutureEither<Color> call() { //! <-- LINT WARNING
    return Future.value.call();
  }
}

// LINT: [16] enforce_file_and_folder_location
// Reason: This is a Repository Implementation (Data Layer), incorrectly placed in the UseCases folder.
// ignore: enforce_annotations, enforce_usecase_contract
class AuthRepositoryImpl { //! <-- LINT WARNING
  const AuthRepositoryImpl();
}