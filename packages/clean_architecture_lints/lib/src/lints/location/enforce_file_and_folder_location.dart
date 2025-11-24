// lib/src/lints/location/enforce_file_and_folder_location.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
import 'package:clean_architecture_lints/src/models/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that enforces that a class is located in the correct architectural
/// directory based on its name.
class EnforceFileAndFolderLocation extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_file_and_folder_location',
    problemMessage: 'A {0} was found in a "{1}" directory, but it belongs in a "{2}" directory.',
    correctionMessage: 'Move this file to the correct directory or rename the class.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final List<_ComponentPattern> _sortedPatterns;

  EnforceFileAndFolderLocation({
    required super.config,
    required super.layerResolver,
  }) : _sortedPatterns = _createSortedPatterns(config.namingConventions.rules),
        super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (_sortedPatterns.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;
      final classElement = node.declaredFragment?.element;

      // 1. Actual Location
      final actualComponent = layerResolver.getComponent(filePath);
      if (actualComponent == ArchComponent.unknown) return;

      // 2. Best Guess based on Name
      final bestMatch = _getBestMatch(className);
      if (bestMatch == null) return;

      final expectedComponent = bestMatch.component;

      // 3. Compare
      if (expectedComponent != actualComponent) {

        // CHECK A: Collision / Specificity Logic
        final actualPattern = _sortedPatterns.firstWhereOrNull(
              (p) => p.component == actualComponent &&
              NamingUtils.validateName(name: className, template: p.pattern),
        );

        if (actualPattern != null) {
          // If Actual pattern is equally specific or MORE specific -> OK.
          if (actualPattern.pattern.length >= bestMatch.pattern.length) {
            return;
          }
        }

        // CHECK B: Inheritance Intent (The Fix)
        // If the class EXTENDS/IMPLEMENTS the type required for the ACTUAL location,
        // we assume the location is correct and the name is just wrong/unique.
        // This prevents "Entity found in Port" errors for classes like 'AuthContract'.
        if (classElement != null && _satisfiesInheritanceRule(classElement, actualComponent)) {
          return;
        }

        reporter.atToken(
          node.name,
          _code,
          arguments: [
            expectedComponent.label, // e.g. "Entity"
            actualComponent.label,   // e.g. "Port"
            expectedComponent.label, // e.g. "Entity"
          ],
        );
      }
    });
  }

  bool _satisfiesInheritanceRule(ClassElement element, ArchComponent targetComponent) {
    final rule = config.inheritances.ruleFor(targetComponent.id);
    if (rule == null || rule.required.isEmpty) return false;
    return rule.required.any((detail) => _hasSupertype(element, detail));
  }

  bool _hasSupertype(ClassElement element, InheritanceDetail detail) {
    if (detail.name == null || detail.import == null) return false;

    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;

      // 1. Name Check
      if (superElement.name != detail.name) return false;

      // 2. URI Check (Robust)
      // [Analyzer 8.0.0] Use firstFragment.source
      final libraryUri = superElement.library.firstFragment.source.uri.toString();
      final configUri = detail.import!;

      // A. Exact Match
      if (libraryUri == configUri) return true;

      // B. Suffix/Path Match (Robust against package vs file URIs)
      final libSuffix = _extractPathSuffix(libraryUri);
      final configSuffix = _extractPathSuffix(configUri);

      if (libSuffix != null && configSuffix != null && libSuffix == configSuffix) {
        return true;
      }

      // Fallback
      if (libraryUri.endsWith(configUri)) return true;

      return false;
    });
  }

  /// Extracts the path relative to the 'lib' folder or the package root.
  String? _extractPathSuffix(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;

    if (uri.scheme == 'package') {
      // package:example/core/port.dart -> core/port.dart
      if (uri.pathSegments.length > 1) {
        return uri.pathSegments.sublist(1).join('/');
      }
    } else if (uri.scheme == 'file') {
      // file:///.../lib/core/port.dart -> core/port.dart
      final segments = uri.pathSegments;
      final libIndex = segments.lastIndexOf('lib');
      if (libIndex != -1 && libIndex < segments.length - 1) {
        return segments.sublist(libIndex + 1).join('/');
      }
    }
    return uriString;
  }

  _ComponentPattern? _getBestMatch(String className) {
    return _sortedPatterns.firstWhereOrNull(
          (p) => NamingUtils.validateName(name: className, template: p.pattern),
    );
  }

  static List<_ComponentPattern> _createSortedPatterns(List<NamingRule> rules) {
    final patterns = rules.expand((rule) {
      return rule.on.map((componentId) {
        final component = ArchComponent.fromId(componentId);
        return component != ArchComponent.unknown
            ? _ComponentPattern(pattern: rule.pattern, component: component)
            : null;
      });
    }).whereNotNull().toList();

    patterns.sort((a, b) => b.pattern.length.compareTo(a.pattern.length));
    return patterns;
  }
}

class _ComponentPattern {
  final String pattern;
  final ArchComponent component;
  const _ComponentPattern({required this.pattern, required this.component});
}