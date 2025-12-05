import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/enums/usage_kind.dart'; // Import Enum
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/usage_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/usages/base/usage_base_rule.dart'; // Import Base
import 'package:custom_lint_builder/custom_lint_builder.dart';

class InstantiationForbiddenRule extends UsageBaseRule {
  static const _code = LintCode(
    name: 'arch_usage_instantiation',
    problemMessage: 'Direct instantiation of "{0}" is forbidden.',
    correctionMessage: 'Inject this dependency via constructor instead.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const InstantiationForbiddenRule() : super(code: _code);

  @override
  void registerListeners({
    required CustomLintContext context,
    required List<UsageConfig> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
  }) {
    // 1. Pre-calculate forbidden target components
    final forbiddenComponents = rules
        .expand((r) => r.forbidden)
        .where((c) => c.kind == UsageKind.instantiation)
        .expand((c) => c.components)
        .toSet();

    if (forbiddenComponents.isEmpty) return;

    // 2. Register Constructor Call Listener
    context.registry.addInstanceCreationExpression((node) {
      final type = node.constructorName.type.type;
      final element = type?.element;

      if (element != null) {
        final library = element.library;
        // Access source via fragment for analyzer 8.x compatibility
        if (library != null) {
          final sourcePath = library.firstFragment.source.fullName;
          final instantiatedComponent = fileResolver.resolve(sourcePath);

          if (instantiatedComponent != null) {
            // Check matching (Suffix/Prefix logic handled by InheritanceLogic mixin)
            final isForbidden = forbiddenComponents.any(
              (id) => componentMatches(id, instantiatedComponent.id),
            );

            if (isForbidden) {
              reporter.atNode(
                node.constructorName,
                _code,
                arguments: [instantiatedComponent.displayName],
              );
            }
          }
        }
      }
    });
  }
}
