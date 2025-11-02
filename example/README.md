# Clean Architecture Kit - Example Project

This Flutter project serves as a comprehensive demonstration of the `clean_architecture_kit` linter package.

## Purpose

The primary purpose of this project is to showcase every single lint rule provided by the package. It is configured to be a "living document" where you can see correct implementations and, more importantly, common architectural violations and the warnings they produce.

## Exploring the Lints

The best way to see the linter in action is to explore the files ending in `.violations.dart`. These files are intentionally filled with code that breaks the architectural rules.

For example, navigate to:

-   `lib/features/auth/domain/contracts/auth_repository.violations.dart`
-   `lib/features/auth/presentation/widgets/login_button.violations.dart`

When you open these files in a configured IDE (like VS Code or Android Studio), you will see warnings and info diagnostics highlighting the exact lines of code that violate the rules defined in `analysis_options.yaml`.

## How to Run

1.  **Ensure the workspace is bootstrapped.** From the root of the monorepo, run:
    ```bash
    melos bootstrap
    ```
2.  **Run the analyzer via Melos:** To run a command-line analysis of this example project, execute the following from the root of the monorepo:
    ```bash
    melos run analyze:example
    ```
3.  **Open in your IDE:** For the best experience, open the entire `clean_architecture_workspace` in your IDE. The Dart analyzer will automatically run in the background, and you'll see the lints appear as you browse the violation files.

## Project Structure

This example uses the **feature-first** project structure, as configured in its `analysis_options.yaml`. All authentication-related code is colocated under `lib/features/auth/`, with `domain`, `data`, and `presentation` sub-folders.