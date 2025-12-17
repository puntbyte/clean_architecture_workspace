import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/lints/architecture_fix.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/policies/member_policy.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/lints/members/base/member_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MemberForbiddenRule extends MemberBaseRule {
  static const _code = LintCode(
    name: 'arch_member_forbidden',
    problemMessage: 'Forbidden member detected: {0}.',
    correctionMessage: 'Remove or modify the member to comply with architectural rules.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const MemberForbiddenRule() : super(code: _code);

  @override
  void checkMembers({
    required ClassDeclaration node,
    required List<MemberPolicy> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
    required ComponentContext component,
  }) {
    for (final member in node.members) {
      for (final rule in rules) {
        // 1. Check Allowed (Whitelist override)
        final isAllowed = rule.allowed.any((c) => matchesConstraint(member, c));
        if (isAllowed) continue;

        // 2. Check Forbidden
        final isForbidden = rule.forbidden.any((c) => matchesConstraint(member, c));

        if (isForbidden) {
          Object? target;

          if (member is MethodDeclaration) {
            target = member.name;
          } else if (member is FieldDeclaration) {
            target = member.fields.variables.firstOrNull?.name;
          } else if (member is ConstructorDeclaration) {
            target = member.name ?? member.returnType;
          }

          _report(
            reporter: reporter,
            nodeOrToken: target ?? node.name,
            code: _code,
            arguments: ['Violates rule for ${component.id}'],
          );
        }
      }
    }
  }

  void _report({
    required DiagnosticReporter reporter,
    required Object nodeOrToken,
    required LintCode code,
    required List<Object> arguments,
  }) {
    if (nodeOrToken is AstNode) {
      reporter.atNode(nodeOrToken, code, arguments: arguments);
    } else if (nodeOrToken is Token) {
      reporter.atToken(nodeOrToken, code, arguments: arguments);
    }
  }
}
