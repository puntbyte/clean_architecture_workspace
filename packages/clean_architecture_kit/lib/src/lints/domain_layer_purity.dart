import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule to enforce that the Domain layer remains independent of outer layers.
///
/// This rule specifically flags any import from the Data or Presentation layers
/// within a file belonging to the Domain layer.
class DomainLayerPurity extends DartLintRule {
  static const _code = LintCode(
    name: 'domain_layer_purity',
    problemMessage:
        'Domain layer purity violation: The domain layer cannot import from the {0} layer.',
    correctionMessage:
        'The Domain layer must be pure. Remove this import and depend on an abstraction if necessary.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const DomainLayerPurity({
    required this.config,
    required this.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // 1. Determine the layer of the current file being analyzed.
    final currentLayer = layerResolver.getLayer(resolver.source.fullName);

    // 2. This lint's logic only applies to files within the domain layer.
    //    If the file is not in the domain layer, we do nothing.
    if (currentLayer != ArchLayer.domain) {
      return;
    }

    // 3. Register a visitor to inspect every import directive in the file.
    context.registry.addImportDirective((node) {
      // Attempt to resolve the full, absolute path of the imported file.
      final importPath = node.libraryImport?.importedLibrary?.firstFragment.source.fullName;
      if (importPath == null) {
        return; // Could not resolve the import (e.g., a Dart SDK import), so we ignore it.
      }

      // 4. Determine the architectural layer of the imported file.
      final importedLayer = layerResolver.getLayer(importPath);

      // 5. Check for the violation: Is the imported layer Data or Presentation?
      if (importedLayer == ArchLayer.data || importedLayer == ArchLayer.presentation) {
        // A violation was found. Report the error at the location of the
        // import statement, providing the name of the invalid layer as an argument.
        reporter.atNode(node, _code, arguments: [importedLayer.name]);
      }
    });
  }
}
