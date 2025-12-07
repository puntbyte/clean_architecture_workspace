// lib/src/lints/safety/rules/type_safety_return_forbidden.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/type_safety_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/safety/base/type_safety_base_rule.dart';
import 'package:architecture_lints/src/lints/safety/logic/type_safety_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class TypeSafetyReturnForbiddenRule extends TypeSafetyBaseRule {
  static const _code = LintCode(
    name: 'arch_safety_return_forbidden',
    problemMessage: 'Invalid Return Type: "{0}" is forbidden.{1}',
    correctionMessage: 'Change the return type to a permitted type.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const TypeSafetyReturnForbiddenRule() : super(code: _code);

  @override
  void checkReturn({
    required MethodDeclaration node,
    required DartType type,
    required List<TypeSafetyConfig> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
  }) {
    // Safety check
    if (node.returnType == null) return;

    for (final rule in rules) {
      final forbidden = rule.forbidden.where((c) => c.kind == 'return').toList();
      final allowed = rule.allowed.where((c) => c.kind == 'return').toList();

      if (forbidden.isEmpty) continue;

      // 1. Get Forbidden Specificity
      final forbiddenSpec = getMatchSpecificity(
        type,
        forbidden,
        fileResolver,
        config.definitions,
      );

      if (forbiddenSpec == MatchSpecificity.none) continue;

      // 2. Get Allowed Specificity
      final allowedSpec = getMatchSpecificity(
        type,
        allowed,
        fileResolver,
        config.definitions,
      );

      // 3. Smart Override Logic (Specific Beats General)
      var shouldReport = true;

      if (allowedSpec != MatchSpecificity.none) {
        if (allowedSpec.index > forbiddenSpec.index) {
          shouldReport = false;
        }
      }

      if (shouldReport) {
        var suggestion = '';
        if (allowed.isNotEmpty) {
          final allowedNames = allowed
              .map((a) => "'${describeConstraint(a, config.definitions)}'")
              .join(' or ');
          suggestion = ' Use $allowedNames instead.';
        }

        // FIX: Branch the logic. Tokens use atToken, Nodes use atNode.
        final returnNode = node.returnType!;

        if (returnNode is NamedType) {
          // Highlight only the name token (e.g. "FutureEither")
          // Use .name2 as .name is deprecated/removed in newer analyzer versions
          reporter.atToken(
            returnNode.name,
            _code,
            arguments: [
              type.getDisplayString(),
              suggestion,
            ],
          );
        } else {
          // Fallback for other types (e.g. GenericFunctionType)
          reporter.atNode(
            returnNode,
            _code,
            arguments: [
              type.getDisplayString(),
              suggestion,
            ],
          );
        }
      }
    }
  }
}
