// lib/src/lints/identity/rules/inheritance_allowed_rule.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/inheritance_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/identity/base/inheritance_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class InheritanceAllowedRule extends InheritanceBaseRule {
  static const _code = LintCode(
    name: 'arch_type_strict_inheritance',
    problemMessage: 'The component "{0}" is not allowed to inherit from "{1}".',
    correctionMessage: 'Only the following types are allowed: {2}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const InheritanceAllowedRule() : super(code: _code);

  @override
  void checkInheritance({
    required ClassDeclaration node,
    required InterfaceElement element,
    required List<InterfaceType> supertypes,
    required List<InheritanceConfig> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
    required ComponentContext component,
  }) {
    for (final rule in rules) {
      if (rule.allowed.isEmpty) continue;

      for (final type in supertypes) {
        // Is this type allowed by ANY of the definitions in the allowed list?
        final isAllowed = rule.allowed.any(
          (def) => matchesDefinition(type, def, fileResolver, config.definitions),
        );

        if (!isAllowed) {
          final descriptions = rule.allowed
              .map((d) => d.describe(config.definitions))
              .join(' OR ');

          report(
            reporter: reporter,
            nodeOrToken: getNodeForType(node, type) ?? node.name,
            code: _code,
            arguments: [
              component.displayName,
              type.element.name ?? 'Unknown',
              descriptions,
            ],
          );
        }
      }
    }
  }
}
