import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/usage_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class UsageBaseRule extends ArchitectureLintRule with InheritanceLogic {
  const UsageBaseRule({required super.code});

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

    // 1. Filter rules relevant to the current component
    final rules = config.usages.where((rule) {
      return rule.onIds.any((id) => componentMatches(id, component.id));
    }).toList();

    if (rules.isEmpty) return;

    // 2. Delegate to subclass to register specific listeners
    registerListeners(
      context: context,
      rules: rules,
      config: config,
      fileResolver: fileResolver,
      reporter: reporter,
    );
  }

  /// Override this to register specific AST node listeners (Identifier vs InstanceCreation).
  void registerListeners({
    required CustomLintContext context,
    required List<UsageConfig> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
  });
}
