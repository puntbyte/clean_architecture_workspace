// lib/src/lints/error_handling/enforce_exception_on_data_source.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids DataSource methods from returning types flagged as "forbidden"
/// in the configuration (e.g., wrapper types like `Either` or `Result`).
class EnforceExceptionOnDataSource extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_exception_on_data_source',
    problemMessage:
    'DataSources should throw exceptions on failure, not return wrapper types like `{0}`.',
    correctionMessage:
    'Change the return type to `{1}` and throw specific exceptions on failure.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceExceptionOnDataSource({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
      CustomLintResolver resolver,
      DiagnosticReporter reporter,
      CustomLintContext context,
      ) {
    final component = layerResolver.getComponent(resolver.source.fullName);

    final isDataSource =
        component == ArchComponent.source ||
            component == ArchComponent.sourceInterface ||
            component == ArchComponent.sourceImplementation;

    if (!isDataSource) return;

    final rules = config.typeSafeties.rulesFor(component);
    if (rules.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      final returnTypeNode = node.returnType;
      if (returnTypeNode == null) return;

      final returnTypeSource = returnTypeNode.toSource();

      for (final rule in rules) {
        // Check Forbidden List
        for (final detail in rule.forbidden) {
          if (detail.element != 'return') continue;
          if (detail.type == null) continue;

          final unsafeTypeName = _resolveTypeName(detail.type!);

          if (returnTypeSource.contains(unsafeTypeName)) {
            // Try to find a suggestion from the 'allowed' list of the same rule
            final suggestion = rule.allowed
                .where((d) => d.element == 'return' && d.type != null)
                .map((d) => _resolveTypeName(d.type!))
                .firstOrNull ?? 'Future<T>';

            reporter.atNode(
              returnTypeNode,
              _code,
              arguments: [unsafeTypeName, suggestion],
            );
            return;
          }
        }
      }
    });
  }

  String _resolveTypeName(String key) {
    final definition = config.typeDefinitions.get(key);
    return definition?.name ?? key;
  }
}
