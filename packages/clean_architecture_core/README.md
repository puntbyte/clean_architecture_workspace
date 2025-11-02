# Clean Architecture Core

[![pub version][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A lightweight, zero-dependency package that provides a set of abstract base classes for building Clean Architecture applications in Dart & Flutter.

## Overview

This package is designed to be the "core" dependency for the `clean_architecture_kit` linter. By using these base classes, the linter will work out-of-the-box with zero configuration.

You can also use this package standalone if you just want a simple, unopinionated foundation for your project's architecture.

## What's Included?

-   **`Repository`**: An abstract interface class to be used as a base for all repository contracts.
    ```dart
    abstract interface class Repository { ... }
    ```
-   **`UseCase`**: Base classes for your business logic interactors.
    -   `UnaryUseCase<ReturnType, ParameterType>`: For use cases that take one parameter.
    -   `NullaryUseCase<ReturnType>`: For use cases that take no parameters.
    ```dart
    abstract interface class UnaryUseCase<ReturnType, ParameterType> extends UseCase {
      FutureEither<ReturnType> call(ParameterType parameter);
    }
    ```
-   **`Failure`**: A simple abstract interface class to represent a failure case in your application's logic.
    ```dart
    abstract interface class Failure { ... }
    ```
-   **`FutureEither<T>`**: A convenient typedef for `Future<Either<Failure, T>>` when using the `fpdart` package.
    ```dart
    typedef FutureEither<ReturnType> = Future<Either<Failure, ReturnType>>;
    ```

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  clean_architecture_core: ^1.0.0
  fpdart: ^1.1.0 # Required for FutureEither
```

## Usage Example

```dart
// In your domain layer
import 'package:clean_architecture_core/clean_architecture_core.dart';
import 'package:fpdart/fpdart.dart';

// 1. Define your repository contract
abstract interface class MyRepository implements Repository {
  FutureEither<String> getSomeData(int id);
}

// 2. Define your use case
final class GetSomeDataUsecase implements UnaryUseCase<String, int> {
  final MyRepository repository;

  const GetSomeDataUsecase(this.repository);

  @override
  FutureEither<String> call(int id) {
    return repository.getSomeData(id);
  }
}
```

---

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[pub_badge]: https://img.shields.io/pub/v/clean_architecture_core.svg
[pub_link]: https://pub.dev/packages/clean_architecture_core