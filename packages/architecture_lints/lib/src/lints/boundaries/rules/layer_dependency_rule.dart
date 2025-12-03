import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/import_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';

class LayerDependencyRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_dep_layer',
    problemMessage: 'Layer "{0}" cannot import from "{1}".',
    correctionMessage: 'Move the file or remove the import.',
  );

  const LayerDependencyRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    ComponentConfig? component,
  }) {
    // If this file isn't part of a defined component, we don't enforce its outgoing rules.
    // (Or you might want to enforce that it can't import ANYTHING internal, but let's stick to config).
    if (component == null) return;

    // We need the package name to resolve 'package:' imports correctly
    final packageName = context.pubspec.name;

    context.registry.addImportDirective((node) {
      // 1. Resolve where this import points to
      final importedPath = ImportResolver.resolvePath(
        node: node,
        currentFilePath: resolver.path,
        packageName: packageName,
      );

      if (importedPath == null) return;

      // 2. Identify what component the imported file belongs to
      // We need to access the FileResolver.
      // Since 'runWithConfig' doesn't pass it directly, we grab it from context
      // (It's safe because ArchitectureLintRule puts it there).
      final fileResolver = context.sharedState[FileResolver] as FileResolver;
      final importedComponent = fileResolver.resolve(importedPath);

      if (importedComponent == null) return;

      // 3. CHECK: Is this import allowed?
      // Logic:
      // A. If they are the same component, it's allowed (intra-layer).
      // B. If not, check the 'dependencies' whitelist/blacklist.

      if (component.id == importedComponent.id) return;

      if (!_isImportAllowed(config, component, importedComponent)) {
        reporter.atNode(
          node,
          _code,
          arguments: [component.id, importedComponent.id],
        );
      }
    });
  }

  bool _isImportAllowed(
      ArchitectureConfig config,
      ComponentConfig current,
      ComponentConfig target,
      ) {
    // This part requires parsing the [5] BOUNDARIES section of your YAML.
    // For now, let's implement the basic logic assuming we have that data.

    // TODO: You need to parse the 'dependencies' map from your YAML into a proper Dart object.
    // Let's assume ArchitectureConfig has a method for this.
    // return config.canImport(current.id, target.id);

    return true; // Placeholder until we parse dependencies
  }
}