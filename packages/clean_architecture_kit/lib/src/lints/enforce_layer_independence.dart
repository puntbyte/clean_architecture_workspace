import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceLayerIndependence extends DartLintRule {
  static const _code = LintCode(
    name: 'enforce_layer_independence',
    problemMessage: 'Invalid layer dependency: The {0} layer cannot import from the {1} layer.',
    correctionMessage:
        'Ensure dependencies flow inwards (e.g., Presentation -> Domain, Data -> Domain).',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const EnforceLayerIndependence({
    required this.config,
    required this.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final currentLayer = layerResolver.getLayer(resolver.source.fullName);
    if (currentLayer == ArchLayer.unknown) return;

    context.registry.addImportDirective((node) {
      final importPath = node.libraryImport?.importedLibrary?.firstFragment.source.fullName;
      if (importPath == null) return;

      final importedLayer = layerResolver.getLayer(importPath);
      if (importedLayer == ArchLayer.unknown || importedLayer == currentLayer) return;

      var isViolation = false;
      if (currentLayer == ArchLayer.domain) {
        if (importedLayer == ArchLayer.data || importedLayer == ArchLayer.presentation) {
          isViolation = true;
        }
      } else if (currentLayer == ArchLayer.presentation) {
        if (importedLayer == ArchLayer.data) {
          isViolation = true;
        }
      }

      if (isViolation) {
        reporter.atNode(node, _code, arguments: [currentLayer.name, importedLayer.name]);
      }
    });
  }
}
