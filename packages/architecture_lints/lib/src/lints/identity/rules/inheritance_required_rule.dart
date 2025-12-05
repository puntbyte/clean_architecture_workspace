import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/inheritance_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/identity/base/inheritance_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class InheritanceRequiredRule extends InheritanceBaseRule {
  static const _code = LintCode(
    name: 'arch_type_missing_base',
    problemMessage: 'The component "{0}" must inherit from "{1}".',
    correctionMessage: 'Extend or implement the required type.',
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
    required ComponentConfig component,
  }) {
    for (final rule in rules) {
      if (rule.required.isEmpty) continue;

      // Check if ANY supertype matches the requirement
      final hasMatch = supertypes.any(
        (type) => matchesReference(
          type,
          rule.required,
          fileResolver,
          config.typeDefinitions,
        ),
      );

      if (!hasMatch) {
        report(
          reporter: reporter,
          nodeOrToken: node.name,
          code: _code,
          arguments: [
            component.name ?? component.id,
            describeReference(rule.required, config.typeDefinitions),
          ],
        );
      }
    }
  }
}
