import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceUsecaseContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_usecase_contract',
    // FIX: ensure spelling is "use case" (two words) for readability
    problemMessage: 'UseCases must extend one of the base use case classes: {0}.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
  );

  static const _defaultBaseNames = {'UnaryUsecase', 'NullaryUsecase'};
  static const _externalPackageUri = 'package:clean_architecture_core/clean_architecture_core.dart';

  final bool _hasCustomRule;

  EnforceUsecaseContract({
    required super.config,
    required super.layerResolver,
  }) : _hasCustomRule = config.inheritances.ruleFor(ArchComponent.usecase.id) != null,
       super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (_hasCustomRule) return;
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.usecase) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;

      final element = node.declaredFragment?.element;
      if (element == null) return;

      final localCoreUri = 'package:${context.pubspec.name}/core/usecase/usecase.dart';

      final hasCorrectSupertype = element.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        final uri = superElement.library.firstFragment.source.uri.toString();

        return _defaultBaseNames.contains(superElement.name) &&
            (uri == _externalPackageUri || uri == localCoreUri);
      });

      if (!hasCorrectSupertype) {
        final expectedNames = _defaultBaseNames.join(' or ');
        reporter.atToken(node.name, _code, arguments: [expectedNames]);
      }
    });
  }
}
