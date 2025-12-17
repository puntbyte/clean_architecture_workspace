import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/lints/architecture_fix.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/policies/member_policy.dart';
import 'package:architecture_lints/src/schema/constraints/member_constraint.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/lints/members/base/member_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MemberRequiredRule extends MemberBaseRule {
  static const _code = LintCode(
    name: 'arch_member_missing',
    problemMessage: 'Missing required member matching: {0}.',
    correctionMessage: 'Add the missing field, method, or constructor.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const MemberRequiredRule() : super(code: _code);

  @override
  List<Fix> getFixes() => [ ArchitectureFix() ];

  @override
  void checkMembers({
    required ClassDeclaration node,
    required List<MemberPolicy> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
    required ComponentContext component,
  }) {
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
  }

  String _describeConstraint(MemberConstraint c) {
    final parts = <String>[];
    if (c.kind != null) parts.add(c.kind!.yamlKey);
    if (c.visibility != null) parts.add(c.visibility!.yamlKey);
    if (c.modifier != null) parts.add(c.modifier!.yamlKey);
    if (c.identifiers.isNotEmpty) parts.add('named "${c.identifiers.join('|')}"');
    return parts.join(' ');
  }
}
