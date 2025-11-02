# Clean Architecture Kit Workspace

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

An opinionated and automated linter for enforcing a strict Clean Architecture in Dart & Flutter projects.

This workspace is a monorepo managed by [Melos](https://melos.invertase.dev) and contains the core linter package, a support library, and an example project.

---

## What is Clean Architecture Kit?

`clean_architecture_kit` is a powerful custom linting package that integrates directly into the Dart analyzer. It helps you and your team maintain architectural boundaries automatically by providing compile-time warnings and errors for common violations.

- **Automated & Unobtrusive:** Get real-time feedback in your IDE without any external tools.
- **Highly Configurable:** Tailor the rules, directory names, and naming conventions to match your project's specific needs.
- **Intelligent Quick Fixes:** Go beyond just finding problems. The linter can generate boilerplate code for you, such as creating UseCases and `toEntity()` mapping methods.

## Packages in this Workspace

| Package                                                                  | Description                                                                                                                              | Version                                         |
|:-------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------|
| [`packages/clean_architecture_kit`](./packages/clean_architecture_kit)   | The main linter package. This is what you'll add to your `pubspec.yaml`.                                                                 | [![pub version][pub_badge_kit]][pub_link_kit]   |
| [`packages/clean_architecture_core`](./packages/clean_architecture_core) | A lightweight, optional support package providing base classes (`Repository`, `UseCase`, etc.) that work with the linter out-of-the-box. | [![pub version][pub_badge_core]][pub_link_core] |
| [`example`](./example)                                                   | An example Flutter project demonstrating all the lints and quick fixes in action.                                                        | N/A                                             |

## Getting Started for Users

To use the linter in your own project, please see the detailed instructions in the [`clean_architecture_kit` README](./packages/clean_architecture_kit/README.md).

## Contributing

This project is managed with Melos. To get started as a contributor:

1.  **Activate Melos:**
    ```bash
    dart pub global activate melos
    ```

2.  **Bootstrap the Workspace:** This links all the local packages together.
    ```bash
    melos bootstrap
    ```

3.  **Run Tests:**
    ```bash
    melos run test
    ```

4.  **Analyze the Example Project:** To see the lints in action while developing, run the analyzer on the example app.
    ```bash
    melos run analyze:example
    ```

---

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[pub_badge_kit]: https://img.shields.io/pub/v/clean_architecture_kit.svg
[pub_link_kit]: https://pub.dev/packages/clean_architecture_kit
[pub_badge_core]: https://img.shields.io/pub/v/clean_architecture_core.svg
[pub_link_core]: https://pub.dev/packages/clean_architecture_core