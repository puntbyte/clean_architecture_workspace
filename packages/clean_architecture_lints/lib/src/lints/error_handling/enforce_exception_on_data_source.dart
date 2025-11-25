// lib/src/lints/error_handling/enforce_exception_on_data_source.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids DataSource methods from returning types flagged as "unsafe"
/// in the configuration (e.g., wrapper types like `Either` or `Result`).
///
/// **Reasoning:** DataSources should return raw data (or Futures of raw data) and
/// throw exceptions on failure. Returning wrapper types implies business logic
/// or error handling that belongs in the Repository.
class EnforceExceptionOnDataSource extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_exception_on_data_source',
    problemMessage:
        'DataSources should throw exceptions on failure, not return wrapper types like `{0}`.',
    correctionMessage: 'Change the return type to `{1}` and throw specific exceptions on failure.',
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

    // Check if this is a DataSource (Interface, Implementation, or generic).
    final isDataSource =
        component == ArchComponent.source ||
        component == ArchComponent.sourceInterface ||
        component == ArchComponent.sourceImplementation;

    if (!isDataSource) return;

    // Get applicable Type Safety rules for this component.
    final rules = config.typeSafeties.rulesFor(component.id);
    if (rules.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      final returnTypeNode = node.returnType;
      if (returnTypeNode == null) return;

      final returnTypeSource = returnTypeNode.toSource();

      for (final rule in rules) {
        for (final detail in rule.returns) {
          // Resolve the real type names from type_definitions if keys are used.
          final unsafeTypeName = _resolveTypeName(detail.unsafeType);
          final safeTypeName = _resolveTypeName(detail.safeType);

          // Check if the return type contains the forbidden (unsafe) type.
          // e.g. "Future<Either<L, R>>" contains "Either".
          // We use a simple string check here which is usually sufficient for wrapper types.
          if (returnTypeSource.contains(unsafeTypeName)) {
            reporter.atNode(
              returnTypeNode,
              _code,
              arguments: [unsafeTypeName, safeTypeName],
            );
            return; // Report once per method.
          }
        }
      }
    });
  }

  /// Resolves a type name from the `type_definitions` config.
  /// If the input matches a key (e.g., 'result.wrapper'), returns the defined name (e.g.,
  /// 'FutureEither').
  /// Otherwise, returns the input as-is (assuming it's a raw class name).
  String _resolveTypeName(String key) {
    final definition = config.typeDefinitions.get(key);
    return definition?.name ?? key;
  }
}
