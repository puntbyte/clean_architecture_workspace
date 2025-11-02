## 2.0.1

### 🧹 Cleanup & Removals

- **Removed unnecessary dependency:** Removed `collection`, `yaml`, and `glob` packages from the 
  lint package. The internal usage was replaced with a small, self-contained helper
  (`_firstWhereOrNull`) to avoid an external dependency for a single helper function.

- **Removed unnecessary code:** Deleted redundant code paths and trimmed record/helper types that 
  were only used for a narrow internal purpose (e.g., replaced a single-use record with a small 
  POD class or helper). This reduces code surface and improves maintainability.

### 🐛 Fixes

- **EnforceFileAndFolderLocation:** Fixed a bug where `enforce_file_and_folder_location` could 
  misclassify classes when naming templates were ambiguous (for example, when users set templates 
  like `{{name}}` for multiple concepts). The rule now:

  * Refuses to treat a plain `{{name}}` template as a reliable name-based match (avoids incorrect 
    matches).

  * Falls back to checking inheritance (`extends` / `implements` / `with`) against configured base 
    class names (e.g. `unaryUseCaseName`, `nullaryUseCaseName`, `repositoryBaseName`) to reliably 
    identify UseCases, Repositories, etc.

  * Normalizes path checks (lowercasing, accepts simple plural forms such as `usecases`) and 
    reliably handles Windows path separators.

  * Reduces false positives (e.g. Entities being flagged as UseCases) and improves lint accuracy 
    across platforms.

### ⚙️ Impact & Migration

- **Action required:** Action required: None for most users. This is an internal cleanup — existing 
  configs will continue to work.

- **Recommendation:** If you use ambiguous naming templates like `{{name}}`, prefer explicit 
  suffixes (e.g. `{{name}}Usecase`) or configure the inheritance block so the linter can perform 
  inheritance-based detection.

## 2.0.0

This is a major release that significantly improves the linter's consistency, power, and user 
experience. It includes **breaking changes** to the package structure and lint names that will 
require users to update their configurations.

### 💥 Breaking Changes

*   **Package Decoupling:** The built-in base classes (`Repository`, `UseCase`, etc.) have been extracted into a new, separate package: `clean_architecture_core`.
    *   **Action Required:** Users must now add `clean_architecture_core` as a dependency to use the default inheritance rules.
    *   **Benefit:** This makes `clean_architecture_kit` a pure linter, allowing advanced users to provide their own base classes without needing to import the kit's defaults. The linter now provides smart defaults automatically if `clean_architecture_core` is used.

*   **Lint Rule Renaming:** All "purity" related lints have been renamed to a more descriptive and consistent `disallow_{Thing}_{In_Context}` format.
    *   **Action Required:** You **must** update the rule names in your `analysis_options.yaml` file.
    *   **Benefit:** The new names are unambiguous and clearly state the purpose of each rule.

| Old Name (`...purity`)             | New Name                                |
|:-----------------------------------|:----------------------------------------|
| `domain_layer_purity`              | `disallow_model_in_domain`              |
| `data_source_purity`               | `disallow_entity_in_data_source`        |
| `presentation_layer_purity`        | `disallow_repository_in_presentation`   |
| `repository_implementation_purity` | `disallow_model_return_from_repository` |

*   **Simplified `recommended.yaml`:** The old `recommended.yaml` file has been removed, as the new smart defaults provided by the `clean_architecture_core` integration make it redundant.

### ✨ Features

*   **New Lint: `enforce_model_inherits_entity`**
    *   A powerful new rule that ensures every `Model` class `extends` or `implements` its corresponding domain `Entity`, guaranteeing structural compatibility.

*   **New Lint: `disallow_use_case_in_widget`**
    *   A new rule (previously `disallow_use_case_in_presentation`) that specifically prevents UI widgets from directly calling a `UseCase`, enforcing proper separation of concerns.

*   **Intelligent `toEntity()` Quick Fix:**
    *   The `enforce_model_to_entity_mapping` lint now provides a single, powerful quick fix to generate the `toEntity()` method **inside** the model class.
    *   **This is no longer a simple boilerplate!** The fix now intelligently inspects the fields of the inherited `Entity` and the `Model` to generate a complete, working mapping.
    *   For fields that exist on both, it generates `field: field,`. For fields the model doesn't have, it generates `field: throw UnimplementedError(...)` to guide the developer.

*   **Improved UseCase Generation:**
    *   The `missing_use_case` quick fix is now more robust. For repository methods with multiple parameters, it automatically generates a `Record` `typedef` for clean, type-safe parameters.

### 🐛 Fixes

*   **Major `LayerResolver` Overhaul:** Fixed numerous bugs in the `LayerResolver` that caused lints to fail silently on certain file structures or platforms (especially Windows). The resolver now correctly and reliably identifies layers and sub-layers.
*   **Fixed Configuration Parsing:** Corrected several bugs in `LayerConfig.fromMap` where incorrect keys were being used, causing `layer_definitions` from `analysis_options.yaml` to be ignored.
*   **Fixed Quick Fix Generation:** Resolved issues with the `dart_style` formatter and the latest `analyzer` API to ensure all generated code (from UseCases and `toEntity` methods) is correctly formatted and error-free.

### ♻️ Refactoring

*   **Centralized Parsing Logic:** All YAML parsing logic from model classes has been refactored into a reusable `ConfigParsingExtension`, making the configuration system more robust and maintainable.

## 1.1.0

* **Fixed:** reduced analyzer version (7.6.0) to avoid conflicts with other packages.

## 1.0.1

* **Fixed:** `pubspec.yaml` dependencies to reduce conflicts.

## 1.0.0

* **Initial stable release of `clean_architecture_kit`.**
* **Comprehensive Linting Suite:**
  * Added powerful "purity" lints (`domain_layer_purity`, `data_source_purity`, 
    `presentation_layer_purity`, `repository_implementation_purity`) to enforce strict layer 
    responsibilities.
  * Added structural lints for layer independence, dependency inversion, file location, and naming 
    conventions.
  * Added type safety and inheritance enforcement lints.
* **Intelligent Code Generation:**
  * Introduced the `missing_use_case` lint, which detects repository methods without a 
    corresponding use case.
  * Added a high-priority Quick Fix (`Create use case for...`) that automatically generates 
    complete, correct, and formatted use case files.
* **Out-of-the-Box Experience:**
  * Shipped with built-in base classes (`Repository`, `UnaryUsecase`, `NullaryUsecase`, 
    `FutureEither`) for an instant, zero-configuration setup.
  * Provided a `recommended.yaml` file to enable all features with a single `include` statement.
* **Flexible Configuration:**
  * Designed a powerful and extensible `analysis_options.yaml` structure.
  * Supports both `feature-first` and `layer-first` project structures.
  * Supports highly configurable, template-based naming conventions.
  _* Supports optional annotations for generated classes to integrate with DI frameworks._