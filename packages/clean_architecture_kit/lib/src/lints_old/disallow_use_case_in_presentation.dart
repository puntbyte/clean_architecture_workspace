import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that flags direct calls to UseCases from within widget files.
///
/// This enforces the principle that business logic should be invoked from a
/// presentation manager (like a BLoC, Cubit, or Provider), not directly
/// from the UI layer.
class DisallowUseCaseInPresentation extends DartLintRule {
  static const _code = LintCode(
    name: 'disallow_use_case_in_presentation',
    problemMessage: 'Widgets should not call UseCases directly.',
    correctionMessage: 'Call the UseCase from a presentation manager (Bloc, Cubit, Provider) and expose state to the widget.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const DisallowUseCaseInPresentation({
    required this.config,
    required this.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This lint should only run on files located in a widget directory.
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.widget) return;

    // We need to inspect every method call in the file.
    context.registry.addMethodInvocation((node) {
      // Get the object or class on which the method is being called.
      final target = node.target;
      if (target == null) return; // This is a top-level function call.

      // Get the fully resolved static type of the target.
      final type = target.staticType;
      if (type == null) return;

      final typeName = type.getDisplayString();
      final useCaseTemplate = config.naming.useCase;

      // Use the shared utility to check if the type's name matches the
      // configured naming convention for a UseCase.
      if (NamingUtils.validateName(name: typeName, template: useCaseTemplate)) {
        // A violation was found. Report it.
        reporter.atNode(node, _code);
      }
    });
  }
}
