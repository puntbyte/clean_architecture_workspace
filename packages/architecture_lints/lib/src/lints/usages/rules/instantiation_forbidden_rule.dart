import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class InstantiationForbiddenRule extends ArchitectureLintRule with InheritanceLogic {
  static const _code = LintCode(
    name: 'arch_usage_instantiation',
    problemMessage: 'Direct instantiation of "{0}" is forbidden.',
    correctionMessage: 'Inject this dependency via constructor instead.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const InstantiationForbiddenRule() : super(code: _code);

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

    final rules = config.usages.where((rule) {
      return rule.onIds.any((id) => componentMatches(id, component.id));
    }).toList();

    if (rules.isEmpty) return;

    final forbiddenComponents = rules
        .expand((r) => r.forbidden)
        .where((c) => c.kind == 'instantiation')
        .expand((c) => c.components)
        .toSet();

    if (forbiddenComponents.isEmpty) return;

    context.registry.addInstanceCreationExpression((node) {
      final type = node.constructorName.type.type;
      final element = type?.element;

      if (element != null && element.library != null) {
        // Resolve component of the class being instantiated
        final sourcePath = element.library!.firstFragment.source.fullName;
        final instantiatedComponent = fileResolver.resolve(sourcePath);

        if (instantiatedComponent != null) {
          // Check if this component is in the forbidden list
          final isForbidden = forbiddenComponents.any(
                (id) => componentMatches(id, instantiatedComponent.id),
          );

          if (isForbidden) {
            reporter.atNode(
              node.constructorName,
              _code,
              arguments: [instantiatedComponent.name ?? instantiatedComponent.id],
            );
          }
        }
      }
    });
  }
}