// lib/src/lints/contract/enforce_usecase_contract.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/configs/inheritances_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that concrete UseCase classes implement one of the base UseCase classes.
class EnforceUsecaseContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_usecase_contract',
    problemMessage: 'UseCases must extend one of the base use case classes: {0}.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
  );

  static const _externalPackageUri = 'package:clean_architecture_core/clean_architecture_core.dart';

  const EnforceUsecaseContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
      CustomLintResolver resolver,
      DiagnosticReporter reporter,
      CustomLintContext context,
      ) {
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.usecase) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return; // Only check concrete implementations

      final element = node.declaredFragment?.element;
      if (element == null) return;

      // 1. Determine Required Supertypes (Custom > Default)
      final customRule = config.inheritances.ruleFor(ArchComponent.usecase);
      final List<InheritanceDetail> requiredSupertypes;

      if (customRule != null && customRule.required.isNotEmpty) {
        requiredSupertypes = customRule.required;
      } else {
        // Default Defaults: Unary/Nullary from External OR Local Core
        final localCoreUri = 'package:${context.pubspec.name}/core/usecase/usecase.dart';
        requiredSupertypes = [
          const InheritanceDetail(name: 'UnaryUsecase', import: _externalPackageUri),
          const InheritanceDetail(name: 'NullaryUsecase', import: _externalPackageUri),
          InheritanceDetail(name: 'UnaryUsecase', import: localCoreUri),
          InheritanceDetail(name: 'NullaryUsecase', import: localCoreUri),
        ];
      }

      // 2. Check Inheritance
      // If the class extends ANY of the required types, it is valid.
      final hasCorrectSupertype = requiredSupertypes.any(
            (detail) => _hasSupertype(element, detail),
      );

      if (!hasCorrectSupertype) {
        final expectedNames = requiredSupertypes
            .map((r) => r.name)
            .where((n) => n != null)
            .toSet()
            .join(' or ');

        reporter.atToken(
          node.name,
          _code,
          arguments: [expectedNames],
        );
      }
    });
  }

  bool _hasSupertype(ClassElement element, InheritanceDetail detail) {
    if (detail.name == null || detail.import == null) return false;

    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;

      // 1. Name Check
      if (superElement.name != detail.name) return false;

      // 2. URI Check
      final libraryUri = superElement.library.firstFragment.source.uri.toString();
      final configUri = detail.import!;

      // A. Exact Match
      if (libraryUri == configUri) return true;

      // B. Suffix Match (Robust for tests/templates)
      final libSuffix = _extractPathSuffix(libraryUri);
      final configSuffix = _extractPathSuffix(configUri);

      if (libSuffix != null && configSuffix != null && libSuffix == configSuffix) {
        return true;
      }

      return libraryUri.endsWith(configUri);
    });
  }

  String? _extractPathSuffix(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;

    if (uri.scheme == 'package') {
      if (uri.pathSegments.length > 1) {
        return uri.pathSegments.sublist(1).join('/');
      }
    } else if (uri.scheme == 'file') {
      final segments = uri.pathSegments;
      final libIndex = segments.lastIndexOf('lib');
      if (libIndex != -1 && libIndex < segments.length - 1) {
        return segments.sublist(libIndex + 1).join('/');
      }
    }
    return uriString;
  }
}
