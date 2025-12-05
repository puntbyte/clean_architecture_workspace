import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/type_safety_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/safety/base/type_safety_base_rule.dart'; // Import Base
import 'package:custom_lint_builder/custom_lint_builder.dart';

class TypeSafetyReturnAllowedRule extends TypeSafetyBaseRule {
  static const _code = LintCode(
    name: 'arch_safety_return_strict',
    problemMessage: 'Invalid Return Type: "{0}" is not allowed.',
    correctionMessage: 'Return one of the allowed types: {1}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const TypeSafetyReturnAllowedRule() : super(code: _code);

  @override
  void checkReturn({
    required MethodDeclaration node,
    required DartType type,
    required List<TypeSafetyConfig> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
  }) {
    for (final rule in rules) {
      final allowed = rule.allowed.where((c) => c.kind == 'return').toList();
      if (allowed.isEmpty) continue;

      final matchesAny = allowed.any(
        (c) => matchesConstraint(type, c, fileResolver, config.typeDefinitions),
      );

      if (!matchesAny) {
        final description = allowed.map(describeConstraint).join(', ');
        reporter.atNode(
          node.returnType!,
          _code,
          arguments: [type.getDisplayString(), description],
        );
      }
    }
  }
}
