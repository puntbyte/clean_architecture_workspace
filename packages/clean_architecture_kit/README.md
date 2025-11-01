# Clean Architecture Kit

[![pub version][pub_version_badge]][pub_package]
[![likes][likes_badge]][pub_package]
[![pub points][pub_points_badge]][pub_package]
[![license][license_badge]][license_file]

A powerful and highly configurable linter toolkit for enforcing Clean Architecture principles in 
Dart & Flutter projects. It not only finds architectural violations but provides powerful quick 
fixes to generate your boilerplate for you.

## Features

- ✅ **Comprehensive Lints:** Enforce layer purity, dependency direction, naming conventions, and 
  more.
- 🚀 **Intelligent Code Generation:** Automatically generate complete `UseCase` classes from your 
  `Repository` interfaces with a single click.
- 📦 **Works Out-of-the-Box:** Includes built-in base classes (`Repository`, `UseCase`, 
  `FutureEither`) for instant productivity.
- 🔧 **Highly Configurable:** Customize everything from folder names to class naming conventions 
  to fit your team's style guide.
- 🏗️ **Future-Proof Design:** Built to be extensible for other architectural patterns in the 
  future.

---

## Getting Started

### 1. Installation

Add `custom_lint` and `clean_architecture_kit` to your `dev_dependencies`.

```sh
dart pub add --dev custom_lint
dart pub add --dev clean_architecture_kit
```

### 2. Configuration

Create an `analysis_options.yaml` file in the root of your project and paste the full configuration 
below. This provides a comprehensive setup that works out-of-the-box with the included base classes.

<details>
<summary>Click to expand the full analysis_options.yaml configuration</summary>

```yaml
# This is the full, recommended configuration for the `clean_architecture_kit` package.
# Copy and paste this entire content into your `analysis_options.yaml` file.

analyzer:
  plugins:
    # The custom_lint framework discovers all other lint packages, like `clean_architecture_kit`,
    # automatically from your project's dev_dependencies.
    - custom_lint

# The top-level `custom_lint` key manages all custom linting.
custom_lint:
  rules:
    # --- ENABLE/DISABLE INDIVIDUAL LINT RULES ---
    # To disable a rule, set its value to `false`.
    
    # Purity Rules
    - domain_layer_purity: true
    - data_source_purity: true
    - presentation_layer_purity: true
    - repository_implementation_purity: true
    - disallow_flutter_imports_in_domain: true
    - disallow_flutter_types_in_domain: true
    
    # Dependency & Structure Rules
    - enforce_layer_independence: true
    - enforce_abstract_data_source_dependency: true
    - enforce_file_and_folder_location: true

    # Naming, Type Safety & Inheritance Rules
    - enforce_naming_conventions: true
    - enforce_custom_return_type: true
    - enforce_use_case_inheritance: true
    - enforce_repository_inheritance: true

    # Code Generation Rule
    - missing_use_case: true

    # --- SHARED CONFIGURATION for the 'clean_architecture_kit' plugin ---
    # The configuration map is provided as a special entry in the rules list.
    - clean_architecture:
      # [SECTION 1: PROJECT STRUCTURE]
      project_structure: 'feature_first' # Options: 'layer_first' or 'feature_first'
    
      # For 'feature_first' structure.
      feature_first_paths:
        features_root: "features"
    
      # For 'layer_first' structure.
      layer_first_paths:
        domain: "domain"
        data: "data"
        presentation: "presentation"
    
      # [SECTION 2: LAYER & DIRECTORY DEFINITIONS]
      # Define the canonical names for your sub-directories.
      layer_definitions:
        domain:
          entities: ['entities']
          repositories: ['contracts']
          use_cases: ['usecases']
        data:
          repositories: ['contracts']
          data_sources: ['sources']
          models: ['models']
        presentation:
          managers: ['bloc', 'cubit', 'provider']
    
      # [SECTION 3: NAMING CONVENTIONS]
      # Use {{name}} as a placeholder for the base name (e.g., 'Auth' in 'AuthRepository').
      naming_conventions:
        model: '{{name}}Model'
        use_case: '{{name}}Usecase'
        use_case_record_parameter: '_{{name}}Params'
        repository_interface: '{{name}}Repository'
        repository_implementation: '{{name}}RepositoryImpl'
        data_source_interface: '{{name}}DataSource'
        data_source_implementation: 'Default{{name}}DataSource'
    
      # [SECTION 4: TYPE SAFETY RULES]
      # These paths point to the base classes provided by `clean_architecture_kit` itself.
      type_safety:
        return_type_name: ['FutureEither']
        import_path: ['package:clean_architecture_kit/clean_architecture_kit.dart']
        apply_to: ['usecases', 'repository_interface']
    
      # [SECTION 5: INHERITANCE AND BASE CLASSES]
      # These paths also point to the base classes provided by `clean_architecture_kit`.
      inheritance:
        repository_base_path: 'package:clean_architecture_kit/clean_architecture_kit.dart'
        repository_base_name: 'Repository'
      
        unary_use_case_path: 'package:clean_architecture_kit/clean_architecture_kit.dart'
        unary_use_case_name: 'UnaryUsecase'
    
        nullary_use_case_path: 'package:clean_architecture_kit/clean_architecture_kit.dart'
        nullary_use_case_name: 'NullaryUsecase'
    
      # [SECTION 6: GENERATION OPTIONS] (Optional)
      # Uncomment and configure this section to add annotations to generated use cases.
      generation_options:
        use_case_annotations:
          - import_path: 'package:injectable/injectable.dart'
            annotation_text: 'Injectable()'
```

</details>

### 3. Usage

You can now import the provided base classes directly from the kit and start coding. The linter 
will guide you.

**Example `auth_repository.dart`:**

```dart
// 1. Import the base classes provided by the kit.
import 'package:clean_architecture_kit/clean_architecture_kit.dart';
import 'package:my_app/features/auth/domain/entities/user_entity.dart';

// 2. Extend the `Repository` base class.
abstract interface class AuthRepository extends Repository {
  // 3. The linter will now detect that this method is missing a use case!
  FutureEither<User> getUser(int id);
}
```

---

## Code Generation in Action

The killer feature of `clean_architecture_kit` is its ability to write your `UseCase` boilerplate 
for you.

When the `missing_use_case` lint detects a repository method without a corresponding use case, it 
will show an informational warning.

1.  Place your cursor on the method name (e.g., `getUser`).
2.  Trigger the quick fix menu (usually `Ctrl + .` or `Cmd + .`).
3.  Select **"Create use case for `getUser`"**.

The kit will instantly generate a new, fully correct, and formatted file.

---

## All Lint Rules

| Rule Name                                 | Purpose                                                                                         |
|:------------------------------------------|:------------------------------------------------------------------------------------------------|
| **Purity Rules**                          |                                                                                                 |
| `domain_layer_purity`                     | Ensures the domain layer does not depend on models or outer layers.                             |
| `data_source_purity`                      | Ensures data sources do not depend on domain entities.                                          |
| `presentation_layer_purity`               | Ensures presentation (Blocs/ViewModels) depends on use cases, not repositories.                 |
| `repository_implementation_purity`        | Ensures public repository methods return entities, not models.                                  |
| `disallow_flutter_imports_in_domain`      | Bans `package:flutter/...` imports in the domain layer.                                         |
| `disallow_flutter_types_in_domain`        | Bans the use of Flutter types (like `Color`) in domain layer signatures.                        |
| **Dependency & Structure Rules**          |                                                                                                 |
| `enforce_layer_independence`              | Enforces the dependency rule (dependencies must flow inwards).                                  |
| `enforce_abstract_data_source_dependency` | Ensures repository implementations depend on data source abstractions, not concretes.           |
| `enforce_file_and_folder_location`        | Verifies that classes are located in their correctly configured directories.                    |
| **Naming, Type & Inheritance**            |                                                                                                 |
| `enforce_naming_conventions`              | Enforces the configured naming conventions for all architectural components.                    |
| `enforce_custom_return_type`              | Ensures repository and use case methods return the configured type (e.g., `FutureEither`).      |
| `enforce_use_case_inheritance`            | Ensures use cases implement a configured base class.                                            |
| `enforce_repository_inheritance`          | Ensures repository interfaces extend a configured base class.                                   |
| **Code Generation**                       |                                                                                                 |
| `missing_use_case`                        | Detects repository methods that are missing a use case and provides a quick fix to generate it. |

[pub_version_badge]: https://img.shields.io/pub/v/clean_architecture_kit.svg
[likes_badge]: https://img.shields.io/pub/likes/clean_architecture_kit
[pub_points_badge]: https://img.shields.io/pub/points/clean_architecture_kit
[license_badge]: https://img.shields.io/github/license/buntbyte/clean_architecture_kit
[pub_package]: https://pub.dev/packages/clean_architecture_kit
[license_file]: https://github.com/puntbyte/clean_architecture_kit/blob/master/LICENSE