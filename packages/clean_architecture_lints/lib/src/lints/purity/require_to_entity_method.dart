// lib/src/lints/purity/require_to_entity_method.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class RequireToEntityMethod extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'require_to_entity_method',
    problemMessage:
        'The model `{0}` must have a `toEntity()` method that returns its corresponding Entity.',
    correctionMessage: 'Add or correct the `toEntity()` method.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const RequireToEntityMethod({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  // Uncomment when Fix implementation is available
  // @override
  // List<Fix> getFixes() => [CreateToEntityMethodFix(config: config)];

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.model) return;

    context.registry.addClassDeclaration((node) {
      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      // 1. Find the Entity Supertype
      final entitySupertypeElement = _findEntitySupertype(classElement);

      // If it doesn't extend an Entity, this rule doesn't apply (handled by another lint maybe)
      if (entitySupertypeElement == null) return;

      final toEntityMethod = node.members.whereType<MethodDeclaration>().firstWhereOrNull(
        (member) => member.name.lexeme == 'toEntity',
      );

      // 2. Missing Method Check
      if (toEntityMethod == null) {
        reporter.atToken(node.name, _code, arguments: [node.name.lexeme]);
        return;
      }

      // 3. Invalid Return Type Check
      final returnType = toEntityMethod.returnType?.type;

      // We check if the return type matches the expected entity supertype
      if (returnType?.element != entitySupertypeElement) {
        if (toEntityMethod.returnType != null) {
          reporter.atNode(toEntityMethod.returnType!, _code, arguments: [node.name.lexeme]);
        } else {
          reporter.atToken(toEntityMethod.name, _code, arguments: [node.name.lexeme]);
        }
      }
    });
  }

  InterfaceElement? _findEntitySupertype(ClassElement classElement) {
    // Check superclass first
    final superElement = classElement.supertype?.element;
    if (superElement != null && _isEntity(superElement)) {
      return superElement;
    }

    // Check interfaces
    for (final interface in classElement.interfaces) {
      if (_isEntity(interface.element)) {
        return interface.element;
      }
    }
    return null;
  }

  bool _isEntity(InterfaceElement element) {
    final source = element.library.firstFragment.source;
    return layerResolver.getComponent(source.fullName) == ArchComponent.entity;
  }
}
