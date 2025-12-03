import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/parsing/config_loader.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// The base class for all Architecture Lints.
///
/// It handles:
/// 1. Locating and loading [ArchitectureConfig] from `architecture.yaml`.
/// 2. Resolving the current file's [ComponentConfig] (what layer/component is this?).
/// 3. Delegating the actual check to [runWithConfig].
abstract class ArchitectureLintRule extends DartLintRule {
  const ArchitectureLintRule({required super.code});

  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    // 1. Check if Config is already injected (useful for Unit Tests with Mocks)
    if (context.sharedState.containsKey(ArchitectureConfig)) {
      await super.startUp(resolver, context);
      return;
    }

    // 2. Load Config from disk based on the file path
    final config = await ConfigLoader.loadFromContext(resolver.path);

    // 3. Store in Shared State so 'run' method can access it
    if (config != null) {
      context.sharedState[ArchitectureConfig] = config;
      context.sharedState[FileResolver] = FileResolver(config);
    }

    await super.startUp(resolver, context);
  }

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // 1. Retrieve Config and Resolver
    final config = context.sharedState[ArchitectureConfig] as ArchitectureConfig?;
    final fileResolver = context.sharedState[FileResolver] as FileResolver?;

    // If config is missing (file not found or parse error), we can't run rules.
    if (config == null || fileResolver == null) return;

    // 2. Resolve the file's architectural role
    // e.g., "This file is a Domain UseCase"
    final component = fileResolver.resolve(resolver.path);

    // 3. Delegate to the concrete rule logic
    runWithConfig(
      context: context,
      reporter: reporter,
      resolver: resolver,
      config: config,
      component: component,
    );
  }

  /// Abstract method that provides the fully resolved [config] and [component].
  ///
  /// [component]: The architectural definition for the current file.
  /// It is `null` if the file does not match any path defined in `architecture.yaml`.
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    ComponentConfig? component,
  });
}
