// lib/src/lints/dependency/disallow_dependency_instantiation.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids classes from creating their own "Service-like" dependencies.
///
/// **Category:** Dependency
///
/// **Reasoning:** In Clean Architecture, "Service" components (Repositories, DataSources,
/// UseCases, Managers) should be injected via the constructor (DI). Creating them directly
/// creates tight coupling.
///
/// **Allowed:** Instantiating "Data" objects (Entities, Models, States, Events, Failures)
/// is allowed and expected.
class DisallowDependencyInstantiation extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_dependency_instantiation',
    problemMessage:
        'Do not instantiate architectural dependencies directly. Inject them via the constructor.',
    correctionMessage: 'Add this class to the constructor parameters instead of creating it here.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowDependencyInstantiation({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // Only run on "Service-like" components that should be using DI.
    // (e.g. Don't run on Entities/Models, they don't usually do DI).
    final currentComponent = layerResolver.getComponent(resolver.source.fullName);
    if (!_isInjectableComponent(currentComponent)) return;

    context.registry.addInstanceCreationExpression((node) {
      // 1. Check Location: Is this happening in a field or constructor initializer?
      // (Instantiating things inside a method body is usually local logic, not dependency wiring).
      if (!_isFieldOrConstructorInitializer(node)) return;

      // 2. Check Target: What are we instantiating?
      final type = node.staticType;
      final element = type?.element;
      if (element == null) return;

      // [Analyzer 8.0.0 Fix] Use firstFragment.source
      final source = element.library?.firstFragment.source;
      if (source == null) return;

      final targetComponent = layerResolver.getComponent(source.fullName);

      // 3. The Violation: Instantiating another Service-like component directly.
      // e.g. Repository instantiating a DataSource = BAD.
      // e.g. Repository instantiating a Model = GOOD (Mapping).
      if (_isServiceComponent(targetComponent)) {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _isInjectableComponent(ArchComponent component) {
    return component == ArchComponent.repository ||
        component == ArchComponent.sourceImplementation ||
        component == ArchComponent.manager ||
        component == ArchComponent.usecase ||
        component == ArchComponent.widget;
  }

  bool _isServiceComponent(ArchComponent component) {
    // These are things that should be injected, not created.
    return component == ArchComponent.repository ||
        component == ArchComponent.source ||
        component == ArchComponent.sourceImplementation ||
        component == ArchComponent.sourceInterface ||
        component == ArchComponent.usecase ||
        component == ArchComponent.manager;
  }

  bool _isFieldOrConstructorInitializer(InstanceCreationExpression node) {
    // Case 1: `final repo = Repository();` (Field Declaration)
    if (node.thisOrAncestorOfType<FieldDeclaration>() != null) return true;

    // Case 2: `MyBloc() : repo = Repository();` (Constructor Initializer)
    if (node.thisOrAncestorOfType<ConstructorFieldInitializer>() != null) return true;

    return false;
  }
}
