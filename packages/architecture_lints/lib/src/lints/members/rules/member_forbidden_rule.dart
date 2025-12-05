import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart'; // Import Token
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:architecture_lints/src/lints/members/logic/member_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MemberForbiddenRule extends ArchitectureLintRule with InheritanceLogic, MemberLogic {
  static const _code = LintCode(
    name: 'arch_member_forbidden',
    problemMessage: 'Forbidden member detected: {0}.',
    correctionMessage: 'Remove or modify the member to comply with architectural rules.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const MemberForbiddenRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentConfig? component,
  }) {
    if (component == null) return;

    final rules = config.members.where((rule) {
      return rule.onIds.any((id) => componentMatches(id, component.id));
    }).toList();

    if (rules.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      for (final member in node.members) {
        for (final rule in rules) {
          // 1. Check Allowed (Whitelist override)
          final isAllowed = rule.allowed.any((c) => matchesConstraint(member, c));
          if (isAllowed) continue;

          // 2. Check Forbidden
          final isForbidden = rule.forbidden.any((c) => matchesConstraint(member, c));

          if (isForbidden) {
            // Identify the target node/token to highlight
            Object? target; // Object? allows Token or AstNode

            if (member is MethodDeclaration) {
              target = member.name; // Token
            } else if (member is FieldDeclaration) {
              // Highlight the first variable name in the list
              target = member.fields.variables.firstOrNull?.name; // Token
            } else if (member is ConstructorDeclaration) {
              // Name is nullable (e.g. ClassName.name), returnType is Identifier (AstNode)
              target = member.name ?? member.returnType;
            }

            // FIX: Use _report helper to safely handle dynamic types
            _report(
              reporter: reporter,
              nodeOrToken: target ?? node.name,
              code: _code,
              arguments: ['Violates rule for ${component.id}'],
            );
          }
        }
      }
    });
  }

  // FIX: Helper to dispatch between atNode and atToken
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
