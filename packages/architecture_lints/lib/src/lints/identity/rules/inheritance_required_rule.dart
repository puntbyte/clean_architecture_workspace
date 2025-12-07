// lib/src/lints/identity/rules/inheritance_required_rule.dart

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

class InheritanceRequiredRule extends InheritanceBaseRule {
  static const _code = LintCode(
    name: 'arch_type_missing_base',
    problemMessage: '{0}', // Generic placeholder
    correctionMessage: 'Extend or implement one of the required types.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const InheritanceRequiredRule() : super(code: _code);

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
      if (rule.required.isEmpty) continue;

      final hasMatch = supertypes.any((type) {
        return rule.required.any(
          (reqDef) => matchesDefinition(type, reqDef, fileResolver, config.definitions),
        );
      });

      if (!hasMatch) {
        // Generate a rich, human-readable message
        final buffer = StringBuffer()
          ..write('The component "${component.displayName}" is invalid. ');

        final descriptions = rule.required
            .map((d) => d.describe(config.definitions))
            .join(' OR ');

        // Check if we are demanding a Component location vs a Class type
        if (rule.required.any((d) => d.component != null)) {
          buffer.write('It must inherit from a class belonging to: $descriptions.');
        } else {
          buffer.write('It must extend or implement: $descriptions.');
        }

        report(
          reporter: reporter,
          nodeOrToken: node.name,
          code: _code,
          arguments: [buffer.toString()],
        );
      }
    }
  }
}
