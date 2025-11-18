// lib/src/lints/error_handling/enforce_exception_on_data_source.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids DataSource methods from returning wrapper types like `Either` or `Result`.
///
/// **Reasoning:** DataSources should throw exceptions on failure, not handle them.
/// This lint intelligently identifies forbidden return types by looking at the `safe_type`
/// values defined in the `type_safeties` configuration.
class EnforceExceptionOnDataSource extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_exception_on_data_source',
    problemMessage:
        'DataSources should throw exceptions on failure, not return wrapper types like '
            'Either/Result.',
    correctionMessage:
        'Change the return type to a simple Future and throw a specific Exception on failure.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceExceptionOnDataSource({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule applies to both the interface and implementation of a DataSource.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.source && component != ArchComponent.sourceImplementation) {
      return;
    }

    // --- NEW LOGIC: Read from the central TypeSafetyConfig ---
    // Get a set of all "safe types" that are used for return values. These are
    // the types (like FutureEither) that are forbidden in a DataSource.
    final forbiddenReturnTypes = config.typeSafeties.rules
        .where((rule) => rule.target == TypeSafetyTarget.return$)
        .map((rule) => rule.safeType)
        .toSet();

    if (forbiddenReturnTypes.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      final returnTypeNode = node.returnType;
      if (returnTypeNode == null) return;

      // Check if the method's return type starts with one of the forbidden names.
      final returnTypeSource = returnTypeNode.toSource();
      if (forbiddenReturnTypes.any(returnTypeSource.startsWith)) {
        reporter.atNode(returnTypeNode, _code);
      }
    });
  }
}
