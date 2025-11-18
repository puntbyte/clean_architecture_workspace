// lib/src/lints/contracts/enforce_use_case_contract.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that concrete UseCase classes implement the base UseCase classes.
class EnforceUseCaseContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_use_case_contract',
    problemMessage: 'UseCases must implement one of the base use case classes: {0}.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  // Hardcoded defaults for the core architectural contracts
  static const _defaultUnaryName = 'UnaryUsecase';
  static const _defaultNullaryName = 'NullaryUsecase';
  static const _defaultPath = 'package:clean_architecture_core/usecase/usecase.dart';

  const EnforceUseCaseContract({required super.config, required super.layerResolver})
    : super(code: _code);

  String _buildExpectedUri(String configPath, CustomLintContext context) {
    if (configPath.startsWith('package:')) return configPath;
    final packageName = context.pubspec.name;
    final sanitizedPath = configPath.startsWith('/') ? configPath.substring(1) : configPath;
    return 'package:$packageName/$sanitizedPath';
  }

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.usecase) return;

    // If user defined a custom rule, defer to the generic enforce_inheritance lint
    final userRule = config.inheritances.rules.firstWhereOrNull((r) => r.on == component.id);
    if (userRule != null) return;

    // Build URIs for both external package and local project
    final expectedCoreUri = _buildExpectedUri(_defaultPath, context);
    final expectedProjectUri = 'package:${context.pubspec.name}/core/usecase/usecase.dart';
    final expectedBaseNames = {_defaultUnaryName, _defaultNullaryName};

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return; // Only check concrete implementations
      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      final hasCorrectSupertype = classElement.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        return expectedBaseNames.contains(superElement.name) &&
            (superElement.library.uri.toString() == expectedCoreUri ||
                superElement.library.uri.toString() == expectedProjectUri);
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(node.name, _code, arguments: [expectedBaseNames.join(' or ')]);
      }
    });
  }
}
