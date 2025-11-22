// lib/src/lints/purity/disallow_entity_in_data_source.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids any reference to a domain `Entity` within a `DataSource`.
///
/// **Category:** Purity
///
/// **Reasoning:** The data layer's responsibility is to deal with raw data and
/// data transfer objects (Models). It must not know about the pure business
/// objects of the domain layer (Entities).
class DisallowEntityInDataSource extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_entity_in_data_source',
    problemMessage: 'DataSources must not depend on or reference domain Entities.',
    correctionMessage: 'Use a data Model (DTO) instead. The repository is responsible for mapping.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowEntityInDataSource({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);

    // This rule applies to the Source interface, implementation, or the generic Source bucket.
    if (component != ArchComponent.sourceInterface &&
        component != ArchComponent.sourceImplementation &&
        component != ArchComponent.source) {
      return;
    }

    // Visit every TypeAnnotation in the file.
    // This visitor automatically recurses into generics (e.g. it visits 'Future' then 'User').
    context.registry.addTypeAnnotation((node) {
      final type = node.type;
      if (type == null) return;

      // FIX: Do not use recursive SemanticUtils.isComponent.
      // Instead, check ONLY the direct element of this specific node.
      // This prevents double-reporting (once for Future<User> and once for User).

      // Get the source file where this type is defined.
      final source = type.element?.library?.firstFragment.source;
      if (source == null) return;

      // Check if that source file belongs to the Entity layer.
      if (layerResolver.getComponent(source.fullName) == ArchComponent.entity) {
        reporter.atNode(node, _code);
      }
    });
  }
}
