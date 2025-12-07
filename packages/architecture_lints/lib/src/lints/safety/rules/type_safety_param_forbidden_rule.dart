// lib/src/lints/safety/rules/type_safety_param_forbidden.dart

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

class TypeSafetyParamForbiddenRule extends TypeSafetyBaseRule {
  static const _code = LintCode(
    name: 'arch_safety_param_forbidden',
    problemMessage: 'Invalid Parameter Type: "{0}" is forbidden for "{1}".{2}',
    correctionMessage: 'Change the parameter type.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const TypeSafetyParamForbiddenRule() : super(code: _code);

  @override
  void checkParameter({
    required FormalParameter node,
    required DartType type,
    required String paramName,
    required List<TypeSafetyConfig> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
  }) {
    for (final rule in rules) {
      // 1. Filter constraints applicable to this parameter name
      final forbidden = rule.forbidden.where((c) => shouldCheckParam(c, paramName)).toList();
      final allowed = rule.allowed.where((c) => shouldCheckParam(c, paramName)).toList();

      if (forbidden.isEmpty) continue;

      // 2. Check Forbidden Specificity
      // Does this type match a forbidden rule? How specifically?
      final forbiddenSpec = getMatchSpecificity(
        type,
        forbidden,
        fileResolver,
        config.definitions,
      );

      if (forbiddenSpec == MatchSpecificity.none) continue;

      // 3. Check Allowed Specificity
      // Does this type match an allowed rule? How specifically?
      final allowedSpec = getMatchSpecificity(
        type,
        allowed,
        fileResolver,
        config.definitions,
      );

      // 4. Smart Override Logic
      var shouldReport = true;

      if (allowedSpec != MatchSpecificity.none) {
        // If the Allowed rule is MORE specific than the Forbidden rule, we suppress the warning.
        //
        // Scenario 1 (Suppress):
        //   Type: IntId (alias of int)
        //   Forbidden: int (Canonical) -> Specificity 1
        //   Allowed: IntId (Alias)     -> Specificity 2
        //   Result: 2 > 1. Suppress.
        //
        // Scenario 2 (Report):
        //   Type: FutureEither (alias)
        //   Forbidden: FutureEither (Alias) -> Specificity 2
        //   Allowed: Future (Canonical)     -> Specificity 1
        //   Result: 1 > 2 is False. Report.

        if (allowedSpec.index > forbiddenSpec.index) {
          shouldReport = false;
        }
      }

      if (shouldReport) {
        // Generate Suggestion
        var suggestion = '';
        if (allowed.isNotEmpty) {
          final allowedNames = allowed
              .map((a) => "'${describeConstraint(a, config.definitions)}'")
              .join(' or ');
          suggestion = ' Use $allowedNames instead.';
        }

        reporter.atNode(
          node,
          _code,
          arguments: [
            type.getDisplayString(),
            paramName,
            suggestion,
          ],
        );
      }
    }
  }
}
