// lib/src/lints/safety/rules/type_safety_param_forbidden.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/type_safety_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/safety/base/type_safety_base_rule.dart';
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
      final forbidden = rule.forbidden.where((c) => shouldCheckParam(c, paramName)).toList();
      final allowed = rule.allowed.where((c) => shouldCheckParam(c, paramName)).toList();

      if (forbidden.isEmpty) continue;

      // 1. Check Forbidden
      final isForbidden = matchesAnyConstraint(type, forbidden, fileResolver, config.definitions);

      if (isForbidden) {
        // 2. Check Allowed Override
        final isAllowed = matchesAnyConstraint(type, allowed, fileResolver, config.definitions);

        if (isAllowed) continue; // Skip reporting

        // 3. Suggestion
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
