// lib/src/lints/enforce_abstract_data_source_dependency.dart

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule to enforce that Repository Implementations depend on DataSource
/// abstractions (interfaces) and not on concrete implementations.
///
/// This is a key part of the Dependency Inversion Principle.
class EnforceAbstractDataSourceDependency extends DartLintRule {
  static const _code = LintCode(
    name: 'enforce_abstract_data_source_dependency',
    problemMessage:
        'Repository implementations must depend on data source abstractions, not '
        'concrete implementations.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const EnforceAbstractDataSourceDependency({
    required this.config,
    required this.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This lint should only run on files located in a data repository directory.
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.dataRepository) return;

    // We only care about constructor dependencies.
    context.registry.addConstructorDeclaration((node) {
      // Iterate over every parameter in the constructor.
      for (final parameter in node.parameters.parameters) {
        // Get the fully resolved semantic type of the parameter.
        final type = parameter.declaredFragment?.element.type;
        if (type == null) continue;

        // Get the type name as a string, and strip any potential nullability indicator.
        var typeName = type.getDisplayString();
        if (typeName.endsWith('?')) {
          typeName = typeName.substring(0, typeName.length - 1);
        }

        // Get the configured naming template for data source implementations.
        final template = config.naming.dataSourceImplementation;

        // Use the shared utility to check if the type name matches the implementation template.
        if (NamingUtils.validateName(name: typeName, template: template)) {
          // If it matches, we have found a violation. Now, construct a helpful
          // correction message by figuring out what the abstract name should be.
          final pattern = template.replaceAll('{{name}}', '([A-Z][a-zA-Z0-9]+)');
          final regex = RegExp('^$pattern\$');
          final match = regex.firstMatch(typeName);
          final baseName = match?.group(1) ?? typeName;
          final abstractName = config.naming.dataSourceInterface.replaceAll('{{name}}', baseName);

          // Report the error using `reportError` to provide the dynamic correction message.
          reporter.reportError(
            Diagnostic.forValues(
              source: resolver.source,
              offset: parameter.offset,
              length: parameter.length,
              diagnosticCode: _code,
              message: _code.problemMessage,
              correctionMessage: 'Depend on the `$abstractName` interface instead of `$typeName`.',
            ),
          );
        }
      }
    });
  }
}
