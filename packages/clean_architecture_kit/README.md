# Clean Architecture Kit

[![pub version][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

An opinionated and automated linter for enforcing a strict Clean Architecture in Dart & Flutter projects. It not only finds architectural violations but provides powerful quick fixes to generate your boilerplate for you.

---

## Features

-   ✅ **Architectural Guardrails:** Automatically detect when you import from a wrong layer, use a data Model in the domain, or depend on a concrete implementation instead of an abstraction.
-   🚀 **Intelligent Quick Fixes:** Go beyond just finding problems. The linter can generate boilerplate code for you, such as creating `UseCase` classes and `toEntity()` mapping methods.
-   📦 **Works Out-of-the-Box:** Integrates seamlessly with the `clean_architecture_core` package, providing a zero-configuration experience for base classes.
-   🔧 **Highly Configurable:** Customize everything from folder names to class naming conventions to fit your team's style guide. Supports both "feature-first" and "layer-first" project structures.

## Getting Started

### 1. Add Dependencies

Add `clean_architecture_kit` and `custom_lint` to your `dev_dependencies`. For the best out-of-the-box experience, also add `clean_architecture_core`.

```yaml
# pubspec.yaml
dependencies:
  # Your other dependencies...
  fpdart: ^1.1.0 # Recommended for Either type
  clean_architecture_core: ^1.0.0 # Provides default base classes

dev_dependencies:
  # Your other dev_dependencies...
  custom_lint: ^0.6.4 # Or latest version
  clean_architecture_kit: ^1.0.0 # Or latest version
```

### 2. Configure `analysis_options.yaml`

Create or update your `analysis_options.yaml` file. Start with this minimal configuration:

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    # IMPORTANT: Only add custom_lint here.
    # clean_architecture_kit is discovered automatically.
    - custom_lint

custom_lint:
  rules:
    # --- Enable all the rules you want from the list below ---
    - disallow_model_in_domain: true
    - enforce_layer_independence: true
    - enforce_naming_conventions: true
    - missing_use_case: true
    # ... and so on for all rules you wish to enable.

    # --- Provide the shared configuration for the plugin ---
    - clean_architecture:
        project_structure: 'feature_first'
        
        feature_first_paths:
          features_root: "features"

        layer_definitions:
          domain:
            entities: ['entities']
            repositories: ['contracts']
            use_cases: ['use_cases']
          data:
            models: ['models']
            repositories: ['repositories']
            data_sources: ['data_sources']

        naming_conventions:
          entity: '{{name}}Entity'
          model: '{{name}}Model'
          use_case: '{{name}}Usecase'
          repository_interface: '{{name}}Repository'
          repository_implementation: '{{name}}RepositoryImpl'
```

### 3. Restart the Analysis Server

In your IDE, restart the Dart analysis server to activate the linter.
-   **VS Code:** Open the Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`) and run `Dart: Restart Analysis Server`.
-   **Android Studio/IntelliJ:** Find the "Dart Analysis" tool window and click the restart icon.

---

## Rules Overview

| Rule | Quick Fix |
| :--- | :---: |
| **Purity & Responsibility Rules** | |
| `disallow_model_in_domain` | |
| `disallow_entity_in_data_source` | |
| `disallow_repository_in_presentation`| |
| `disallow_model_return_from_repository` | |
| `disallow_use_case_in_widget` | |
| `disallow_flutter_imports_in_domain`| |
| `disallow_flutter_types_in_domain`| |
| `enforce_model_to_entity_mapping`| ✅ |
| `enforce_model_inherits_entity` | |
| **Dependency & Structure Rules** | |
| `enforce_layer_independence` | |
| `enforce_abstract_data_source_dependency` | |
| `enforce_file_and_folder_location`| |
| **Naming, Type Safety & Inheritance** | |
| `enforce_naming_conventions` | |
| `enforce_custom_return_type`| |
| `enforce_use_case_inheritance`| |
| `enforce_repository_inheritance`| |
| **Code Generation** | |
| `missing_use_case` | ✅ |

---

## Detailed Lint Rule Explanations

### `disallow_model_in_domain`
-   **Purpose:** To prevent data-layer **Models** from leaking into the **Domain Layer**.
-   **Description:** This is the core data purity rule for the domain layer. It inspects all method signatures (return types, parameters) and fields and flags any type that matches the naming convention for a `Model`, ensuring the domain only uses pure `Entities`.

<details>
<summary>✅ Good Example</summary>

````dart
// Domain layer file
abstract interface class AuthRepository {
  // Correct: Uses a pure `UserEntity`.
  FutureEither<UserEntity> getUser(String id);
}
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// Domain layer file
abstract interface class AuthRepository {
  // VIOLATION: Uses a `UserModel` from the data layer.
  FutureEither<UserModel> getUser(String id); // <-- LINT WARNING HERE
}
````
</details>

### `disallow_entity_in_data_source`
-   **Purpose:** To prevent domain-layer **Entities** from leaking into the **Data Source Layer**.
-   **Description:** Enforces that Data Sources (classes that fetch raw data from an API or database) speak in terms of raw data types or `Models`, not pure domain `Entities`. The repository is responsible for the mapping.

<details>
<summary>✅ Good Example</summary>

````dart
// Data Source file
abstract interface class AuthRemoteDataSource {
  // Correct: Returns a `UserModel`.
  Future<UserModel> getUser(String id);
}
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// Data Source file
abstract interface class AuthRemoteDataSource {
  // VIOLATION: Returns a pure `UserEntity`.
  Future<UserEntity> getUser(String id); // <-- LINT WARNING HERE
}
````
</details>

### `disallow_repository_in_presentation`
-   **Purpose:** To decouple the **Presentation Layer** from the data access implementation details.
-   **Description:** Prevents presentation logic classes (like BLoCs, Cubits, or Providers) from depending directly on a `Repository`. The presentation layer should only depend on specific `UseCases` to execute business logic.

<details>
<summary>✅ Good Example</summary>

````dart
// Presentation manager file
class AuthBloc {
  // Correct: Depends on a specific UseCase.
  final GetUserUsecase _getUserUsecase;
  AuthBloc(this._getUserUsecase);
}
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// Presentation manager file
class AuthBloc {
  // VIOLATION: Depends on the entire repository.
  final AuthRepository _repository;
  AuthBloc(this._repository); // <-- LINT WARNING HERE
}
````
</details>

### `disallow_model_return_from_repository`
-   **Purpose:** To ensure the **Repository Implementation** correctly maps data `Models` to domain `Entities`.
-   **Description:** This lint checks the public methods in a `RepositoryImpl` class. It enforces that the final return type is a pure `Entity`, guaranteeing that the mapping from `Model` to `Entity` happens inside the repository before the data is returned to a `UseCase`.

<details>
<summary>✅ Good Example</summary>

````dart
// Repository implementation file
class AuthRepositoryImpl implements AuthRepository {
  @override
  FutureEither<UserEntity> getUser(String id) async {
    // ... fetches userModel
    return Right(userModel.toEntity()); // Correct: Returns an Entity.
  }
}
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// Repository implementation file
class AuthRepositoryImpl implements AuthRepository {
  @override
  // VIOLATION: Method returns a `UserModel` instead of a `UserEntity`.
  FutureEither<UserModel> getUser(String id) async { // <-- LINT WARNING HERE
    return const Right(UserModel(id: '1'));
  }
}
````
</details>

### `disallow_use_case_in_widget`
-   **Purpose:** To keep UI components clean of business logic invocation.
-   **Description:** Prevents UI widgets from directly calling a `UseCase`. All business logic should be triggered from a presentation manager (BLoC, Cubit, Provider), which then calls the `UseCase` and exposes the result as state to the UI.

<details>
<summary>✅ Good Example</summary>

````dart
// A widget that receives state from a BLoC/Provider.
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Correct: Listens to a provider to get data.
    final user = ref.watch(userProvider); 
    return Text(user.name);
  }
}
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// A widget that calls a use case directly.
class UserProfile extends StatelessWidget {
  final GetUserUsecase _usecase;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: () {
      // VIOLATION: Calling a use case from a widget.
      _usecase.call('123'); // <-- LINT WARNING HERE
    });
  }
}
````
</details>

### `disallow_flutter_imports_in_domain`
-   **Purpose:** To ensure the **Domain Layer** is platform-agnostic.
-   **Description:** Disallows any `import 'package:flutter/...'` statement in any domain layer file, guaranteeing that your core business logic is pure Dart and can be tested without a Flutter environment.

<details>
<summary>✅ Good Example</summary>
````dart
// domain/entities/user_entity.dart
// Correct: No Flutter imports.
import 'package:meta/meta.dart';

class UserEntity { ... }
````
</details>

<details>
<summary>❌ Bad Example</summary>
````dart
// domain/entities/user_entity.dart
// VIOLATION: Importing a Flutter package.
import 'package:flutter/material.dart'; // <-- LINT WARNING HERE

class UserEntity { ... }
````
</details>

### `disallow_flutter_types_in_domain`
-   **Purpose:** To prevent UI-specific data types from polluting the **Domain Layer**.
-   **Description:** A companion to the rule above, this lint inspects method signatures and fields and disallows any types from the Flutter SDK, such as `Color`, `IconData`, or `Widget`.

<details>
<summary>✅ Good Example</summary>
````dart
// domain/entities/user_entity.dart
class UserEntity {
  // Correct: Uses pure Dart types.
  final String id;
  final int profileColorValue; // Storing as an integer is platform-agnostic.
}
````
</details>

<details>
<summary>❌ Bad Example</summary>
````dart
// domain/entities/user_entity.dart
import 'package:flutter/material.dart';

class UserEntity {
final String id;
// VIOLATION: `Color` is a Flutter type.
final Color profileColor; // <-- LINT WARNING HERE
}
````
</details>

### `enforce_model_to_entity_mapping`
-   **Purpose:** To ensure every **Model** has a defined way to be converted into an **Entity**.
-   **Description:** This lint checks every class that matches the `Model` naming convention and verifies that it has a `toEntity()` method. This guarantees a consistent mapping pattern across the entire data layer.

<details>
<summary>✅ Good Example</summary>

````dart
// data/models/user_model.dart
class UserModel extends UserEntity {
  // ... fields ...

  // Correct: The method exists.
  UserEntity toEntity() => UserEntity(id: id, name: name);
}
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// data/models/user_model.dart
// VIOLATION: The `toEntity()` method is missing.
class UserModel extends UserEntity { // <-- LINT WARNING HERE
  // ... fields ...
  // Missing the `toEntity()` method.
}
````
</details>

### `enforce_model_inherits_entity`
-   **Purpose:** To guarantee structural compatibility between a **Model** and its **Entity**.
-   **Description:** Enforces that a class matching the `Model` naming convention must `extend` or `implement` its corresponding `Entity`. This makes the `toEntity()` mapping process safer and more logical.

<details>
<summary>✅ Good Example</summary>

````dart
// data/models/user_model.dart
// Correct: Inherits from the entity.
class UserModel extends UserEntity { ... }
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// data/models/user_model.dart
// VIOLATION: `UserModel` does not extend or implement `UserEntity`.
class UserModel { ... } // <-- LINT WARNING HERE
````
</details>

### `enforce_layer_independence`
-   **Purpose:** To enforce the correct dependency flow for the entire application.
-   **Description:** This is the master rule for dependency direction. It checks `import` statements and ensures that Presentation -> Domain and Data -> Domain, but **never** the other way around.

<details>
<summary>✅ Good Example</summary>

````dart
// presentation/bloc/auth_bloc.dart
// Correct: The presentation layer imports from the domain layer.
import 'package:my_app/features/auth/domain/usecases/login_usecase.dart';
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// domain/usecases/login_usecase.dart
// VIOLATION: The domain layer cannot import from the data layer.
import 'package:my_app/features/auth/data/models/user_model.dart'; // <-- LINT WARNING HERE
````
</details>

### `enforce_abstract_data_source_dependency`
-   **Purpose:** To enforce the Dependency Inversion Principle.
-   **Description:** Ensures that your `RepositoryImpl` depends on a **data source abstraction** (e.g., `AuthDataSource`) and not a **concrete implementation** (e.g., `DefaultAuthDataSource`).

<details>
<summary>✅ Good Example</summary>

````dart
// data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  // Correct: Depends on the abstraction.
  final AuthDataSource _dataSource;
  AuthRepositoryImpl(this._dataSource);
}
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  // VIOLATION: Depends on the concrete implementation.
  final DefaultAuthDataSource _dataSource;
  AuthRepositoryImpl(this._dataSource); // <-- LINT WARNING HERE
}
````
</details>

### `enforce_file_and_folder_location`
-   **Purpose:** To ensure files are located in the correct directories based on their names.
-   **Description:** This lint checks if a class named, for example, `AuthRepository` is located in a directory configured for domain repositories (e.g., `.../domain/contracts/`).

<details>
<summary>✅ Good Example</summary>

````
// File is located at: lib/features/auth/domain/contracts/auth_repository.dart
// Correct: Location matches the `layer_definitions` config.
abstract interface class AuthRepository { ... }
````
</details>

<details>
<summary>❌ Bad Example</summary>

````
// File is located at: lib/features/auth/domain/repositories/auth_repository.dart
// VIOLATION: The configured path is 'contracts', not 'repositories'.
abstract interface class AuthRepository { ... } // <-- LINT WARNING HERE
````
</details>

### `enforce_naming_conventions`
-   **Purpose:** To ensure all major classes follow a consistent naming format.
-   **Description:** This lint checks the names of classes in different sub-layers (`Entity`, `Model`, `UseCase`, `Repository`, `DataSource`) and verifies they match the templates defined in your configuration (e.g., `{{name}}Repository`).

<details>
<summary>✅ Good Example</summary>

````dart
// In a repository file:
// Correct: Name matches the `{{name}}Repository` template.
abstract interface class AuthRepository { ... }
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// In a repository file:
// VIOLATION: Name does not match the `{{name}}Repository` template.
abstract interface class AuthRepo { ... } // <-- LINT WARNING HERE
````
</details>

### `enforce_custom_return_type`
-   **Purpose:** To enforce that all asynchronous operations in the domain and data layers return a consistent type.
-   **Description:** This lint checks the return types of methods in `UseCases` and `Repository` interfaces and ensures they match the configured type, which is typically a `Result` or `Either` type like your `FutureEither`.

<details>
<summary>✅ Good Example</summary>

````dart
// In a repository file:
abstract interface class AuthRepository {
  // Correct: Returns the configured `FutureEither` type.
  FutureEither<UserEntity> getUser(String id);
}
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// In a repository file:
abstract interface class AuthRepository {
  // VIOLATION: Returns a raw Future, not `FutureEither`.
  Future<UserEntity> getUser(String id); // <-- LINT WARNING HERE
}
````
</details>

### `enforce_use_case_inheritance`
-   **Purpose:** To ensure all use case classes adhere to a standard contract.
-   **Description:** This lint verifies that any class identified as a `UseCase` extends or implements one of the base classes from `clean_architecture_core` (`UnaryUseCase` or `NullaryUseCase`).

<details>
<summary>✅ Good Example</summary>

````dart
// In a use case file:
// Correct: Implements the base `UnaryUseCase`.
class GetUserUsecase implements UnaryUseCase<UserEntity, String> { ... }
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// In a use case file:
// VIOLATION: Is a plain class, does not implement a base use case.
class GetUserUsecase { ... } // <-- LINT WARNING HERE
````
</details>

### `enforce_repository_inheritance`
-   **Purpose:** To ensure all repository interfaces adhere to a standard contract.
-   **Description:** This lint verifies that any abstract class identified as a domain `Repository` extends or implements the base `Repository` class from `clean_architecture_core`.

<details>
<summary>✅ Good Example</summary>

````dart
// In a repository file:
// Correct: Implements the base `Repository`.
abstract interface class AuthRepository implements Repository { ... }
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// In a repository file:
// VIOLATION: Is a plain interface, does not implement the base `Repository`.
abstract interface class AuthRepository { ... } // <-- LINT WARNING HERE
````
</details>

### `missing_use_case`
-   **Purpose:** To identify business logic in a repository that does not have a corresponding `UseCase`.
-   **Description:** This is an "assistant" lint. It scans the methods of a `Repository` interface and checks if a corresponding `UseCase` file exists. If not, it provides a warning and a **Quick Fix** to generate the boilerplate `UseCase` class automatically.

<details>
<summary>✅ Good Example</summary>

````dart
// In a repository file:
// (No warning appears because `lib/.../usecases/get_user_usecase.dart` exists)
abstract interface class AuthRepository implements Repository {
  FutureEither<UserEntity> getUser(String id);
}
````
</details>

<details>
<summary>❌ Bad Example</summary>

````dart
// In a repository file:
abstract interface class AuthRepository implements Repository {
  // VIOLATION: No file exists at `lib/.../usecases/login_usecase.dart`.
  FutureEither<void> login(String email, String password); // <-- LINT WARNING HERE
}
````
</details>

---

## Full Configuration

For a complete, well-documented configuration file with all available options, please refer to the `analysis_options.yaml` in our [example project](../example/analysis_options.yaml).

---

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[pub_badge]: https://img.shields.io/pub/v/clean_architecture_kit.svg
[pub_link]: https://pub.dev/packages/clean_architecture_kit