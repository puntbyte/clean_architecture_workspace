// lib/src/lints/enforce_naming_pattern.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/models/configs/inheritances_config.dart';
import 'package:architecture_lints/src/utils/nlp/naming_strategy.dart';
import 'package:architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceNamingPattern extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_naming_pattern',
    problemMessage: 'The name `{0}` does not match the required `{1}` convention for a {2}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final NamingStrategy _namingStrategy;

  EnforceNamingPattern({
    required super.config,
    required super.layerResolver,
  }) : _namingStrategy = NamingStrategy(config.namingConventions.rules),
        super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;

      final actualComponent = layerResolver.getComponent(filePath, className: className);
      if (actualComponent == ArchComponent.unknown) return;

      final rule = config.namingConventions.ruleFor(actualComponent);
      if (rule == null) return;

      // Check if inheritance is valid (e.g. Model extends Entity)
      final element = node.declaredFragment?.element;
      final isInheritanceValid = element != null &&
          _satisfiesInheritanceRule(element, actualComponent);

      // Pass to strategy: If inheritance is valid, DO NOT YIELD (Report naming error)
      if (_namingStrategy.shouldYieldToLocationLint(
        className,
        actualComponent,
        isInheritanceValid,
      )) {
        return;
      }

      if (!NamingUtils.validateName(name: className, template: rule.pattern)) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [className, rule.pattern, actualComponent.label],
        );
      }
    });
  }

  // --- Inheritance Check Logic (Shared Logic) ---
  bool _satisfiesInheritanceRule(ClassElement element, ArchComponent targetComponent) {
    final rule = config.inheritances.ruleFor(targetComponent);
    if (rule == null || rule.required.isEmpty) return false;
    return rule.required.any((detail) => _hasSupertype(element, detail));
  }

  bool _hasSupertype(ClassElement element, InheritanceDetail detail) {
    if (detail.component != null) {
      final requiredComponent = ArchComponent.fromId(detail.component!);
      if (requiredComponent == ArchComponent.unknown) return false;
      return element.allSupertypes.any((supertype) {
        final source = supertype.element.library.firstFragment.source;
        return layerResolver.getComponent(source.fullName) == requiredComponent;
      });
    }
    if (detail.name == null || detail.import == null) return false;

    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;
      if (superElement.name != detail.name) return false;
      final libraryUri = superElement.library.firstFragment.source.uri.toString();
      final configUri = detail.import!;

      if (libraryUri == configUri) return true;
      if (libraryUri.endsWith(configUri)) return true;
      // Suffix check
      if (_extractPathSuffix(libraryUri) == _extractPathSuffix(configUri)) return true;

      return false;
    });
  }

  String? _extractPathSuffix(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;
    if (uri.scheme == 'package') {
      if (uri.pathSegments.length > 1) return uri.pathSegments.sublist(1).join('/');
    } else if (uri.scheme == 'file') {
      final segments = uri.pathSegments;
      final libIndex = segments.lastIndexOf('lib');
      if (libIndex != -1 && libIndex < segments.length - 1) return segments.sublist(libIndex + 1).join('/');
    }
    return uriString;
  }
}