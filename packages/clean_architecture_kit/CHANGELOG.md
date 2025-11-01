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
  * Supports optional annotations for generated classes to integrate with DI frameworks.