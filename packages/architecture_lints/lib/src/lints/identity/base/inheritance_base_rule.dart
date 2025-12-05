import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/inheritance_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class InheritanceBaseRule extends ArchitectureLintRule with InheritanceLogic {
  const InheritanceBaseRule({required super.code});

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

    // 1. Filter Rules for this component
    final rules = config.inheritances.where((rule) {
      return rule.onIds.any((id) => componentMatches(id, component.id));
    }).toList();

    if (rules.isEmpty) return;

    // 2. Register Listener
    context.registry.addClassDeclaration((node) {
      // Access element via declaredFragment (Analyzer 8.x+)
      final element = node.declaredFragment?.element;
      if (element == null) return;

      // 3. Get Supertypes once
      final supertypes = getImmediateSupertypes(element);

      // 4. Delegate to specific implementation
      checkInheritance(
        node: node,
        element: element,
        supertypes: supertypes,
        rules: rules,
        config: config,
        fileResolver: fileResolver,
        reporter: reporter,
        component: component,
      );
    });
  }

  /// Override this to implement the specific inheritance check logic.
  void checkInheritance({
    required ClassDeclaration node,
    required InterfaceElement element,
    required List<InterfaceType> supertypes,
    required List<InheritanceConfig> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
    required ComponentConfig component,
  });
}