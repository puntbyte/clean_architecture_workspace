// lib/src/lints/structure/enforce_type_safety.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/configs/type_safeties_config.dart';
import 'package:clean_architecture_lints/src/utils/ast/ast_utils.dart';
import 'package:clean_architecture_lints/src/utils/ast/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceTypeSafety extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_type_safety',
    problemMessage: '{0}',
    correctionMessage: 'Consider refactoring to use the safer type.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceTypeSafety({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (config.typeSafeties.rules.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      final parent = node.parent;
      final className = parent is ClassDeclaration ? parent.name.lexeme : null;
      final component = layerResolver.getComponent(resolver.source.fullName, className: className);

      if (component == ArchComponent.unknown) return;

      final rules = config.typeSafeties.rulesFor(component.id);
      if (rules.isEmpty) return;

      // Check Return Type
      final returnTypeNode = node.returnType;
      if (returnTypeNode != null) {
        _checkSafety(
          node: returnTypeNode,
          type: returnTypeNode.type,
          kind: 'return',
          identifier: null,
          rules: rules,
          reporter: reporter,
        );
      }

      // Check Parameters
      for (final parameter in node.parameters?.parameters ?? <FormalParameter>[]) {
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        if (typeNode != null) {
          _checkSafety(
            node: typeNode,
            type: typeNode.type,
            kind: 'parameter',
            identifier: parameter.name?.lexeme,
            rules: rules,
            reporter: reporter,
          );
        }
      }
    });
  }

  void _checkSafety({
    required AstNode node,
    required DartType? type,
    required String kind,
    required String? identifier,
    required List<TypeSafetyRule> rules,
    required DiagnosticReporter reporter,
  }) {
    if (type == null) return;

    for (final rule in rules) {
      // Check Forbidden (Blacklist)
      for (final detail in rule.forbidden) {
        if (!_isRuleApplicable(detail, kind, identifier)) continue;

        if (_matchesDetail(type, detail)) {
          final typeName = _resolveTypeName(detail.type) ?? detail.type ?? 'Unknown';
          reporter.atNode(node, _code, arguments: ['Usage of `$typeName` is forbidden here.']);

          return;
        }
      }

      // Check Allowed (Whitelist)
      final applicableAllowed = rule.allowed
          .where((d) => _isRuleApplicable(d, kind, identifier))
          .toList();

      if (applicableAllowed.isNotEmpty) {
        final matchedAny = applicableAllowed.any((detail) => _matchesDetail(type, detail));

        if (!matchedAny) {
          final allowedNames = applicableAllowed
              .map((d) => _resolveTypeName(d.type) ?? d.type ?? d.component ?? 'Unknown')
              .toSet()
              .join('` or `');

          final foundType = _getEffectiveTypeName(type);

          reporter.atNode(
            node,
            _code,
            arguments: ['Expected type `$allowedNames`, but found `$foundType`.'],
          );

          return;
        }
      }
    }
  }

  bool _isRuleApplicable(TypeSafetyDetail detail, String currentKind, String? currentIdentifier) {
    if (detail.kind != null && detail.kind != currentKind) return false;

    if (detail.identifier != null) {
      if (currentIdentifier == null) return false;
      if (!currentIdentifier.toLowerCase().contains(detail.identifier!.toLowerCase())) return false;
    }

    return true;
  }

  bool _matchesDetail(DartType type, TypeSafetyDetail detail) {
    // 1. Check Component
    if (detail.component != null) {
      final targetComp = ArchComponent.fromId(detail.component!);
      if (SemanticUtils.isComponent(type, layerResolver, targetComp)) return true;
    }

    // Check Type Name
    final targetName = _resolveTypeName(detail.type);
    if (targetName != null) {
      final typeName = _getEffectiveTypeName(type);

      // Exact Match
      if (typeName == targetName) return true;

      // Generics Match (e.g. Future<User> starts with Future)
      if (typeName.startsWith('$targetName<')) return true;
    }

    return false;
  }

  String _getEffectiveTypeName(DartType type) {
    // Handle Aliases (e.g. typedef IntId = int)
    if (type.alias != null) {
      final aliasName = type.alias!.element.name;
      if (aliasName != null) return aliasName;
    }

    // Handle Standard Types
    return type.element?.name ?? type.getDisplayString();
  }

  String? _resolveTypeName(String? rawType) {
    if (rawType == null) return null;
    final definition = config.typeDefinitions.get(rawType);

    return definition?.name ?? rawType;
  }
}
