// lib/src/lints/dependency_injection/disallow_service_locator.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowServiceLocator extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_service_locator',
    problemMessage:
        'Do not use a service locator. Dependencies should be explicit and injected via the '
        'constructor.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowServiceLocator({
    required super.config,
    required super.componentResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = componentResolver.resolveComponent(resolver.source.fullName);
    if (component == null) return;

    final locatorNames = config.services.dependencyInjection.serviceLocatorNames.toSet();
    if (locatorNames.isEmpty) return;

    final locatorNameSet = locatorNames.toSet();

    context.registry.addMethodInvocation((node) {
      // A service locator call is typically a top-level function call, so `target` is null.
      if (node.target == null && locatorNameSet.contains(node.methodName.name)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
