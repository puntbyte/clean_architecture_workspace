// lib/src/lints/error_handling/enforce_exception_on_data_source.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids DataSource methods from returning wrapper types like `Either` or `Result`.
///
/// **Reasoning:** DataSources represent the outermost boundary of the data layer.
/// They are expected to interact with external services (APIs, databases) that can
/// fail. The clean architecture convention is for these sources to throw specific,
/// typed exceptions on failure. The Repository layer is then responsible for
/// catching these exceptions and converting them into business-friendly `Failure`
/// objects, typically wrapped in an `Either` type. This prevents raw exceptions
/// from leaking into the domain or presentation layers.
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
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.source && component != ArchComponent.sourceImplementation) {
      return;
    }

    // Get a set of all "safe types" that are used for return values from the config.
    // These are the types (like FutureEither) that are forbidden in a DataSource.
    final forbiddenReturnTypes = config.typeSafeties.rules
        .expand((rule) => rule.returns)
        .map((detail) => detail.safeType)
        .toSet();

    if (forbiddenReturnTypes.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      final returnTypeNode = node.returnType;
      if (returnTypeNode == null) return;

      final returnTypeSource = returnTypeNode.toSource();

      // Check if the method's return type contains any of the forbidden type names.
      // This is more robust than `startsWith` as it handles generic types like Future<Either<...>>.
      for (final forbiddenType in forbiddenReturnTypes) {
        if (returnTypeSource.contains(forbiddenType)) {
          reporter.atNode(returnTypeNode, _code);
          // Report once per method and stop checking.
          return;
        }
      }
    });
  }
}
