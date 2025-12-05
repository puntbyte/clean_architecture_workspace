import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/member_constraint.dart'; // Import this
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:architecture_lints/src/lints/members/logic/member_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MemberRequiredRule extends ArchitectureLintRule with InheritanceLogic, MemberLogic {
  static const _code = LintCode(
    name: 'arch_member_missing',
    problemMessage: 'Missing required member matching: {0}.',
    correctionMessage: 'Add the missing field, method, or constructor.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const MemberRequiredRule() : super(code: _code);

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
      final members = node.members;

      for (final rule in rules) {
        for (final constraint in rule.required) {
          final hasMatch = members.any((m) => matchesConstraint(m, constraint));

          if (!hasMatch) {
            reporter.atToken(
              node.name,
              _code,
              arguments: [_describeConstraint(constraint)],
            );
          }
        }
      }
    });
  }

  // FIX: Use MemberConstraint instead of dynamic
  String _describeConstraint(MemberConstraint c) {
    final parts = <String>[];
    if (c.kind != null) parts.add(c.kind!);
    if (c.visibility != null) parts.add(c.visibility!);
    if (c.modifier != null) parts.add(c.modifier!);
    if (c.identifiers.isNotEmpty) parts.add('named "${c.identifiers.join('|')}"');
    return parts.join(' ');
  }
}