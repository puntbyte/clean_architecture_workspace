import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ExternalDependencyRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_dep_external',
    problemMessage: 'External dependency violation: "{0}" cannot depend on "{1}".',
    correctionMessage: 'Remove the usage. This layer should be framework-agnostic.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ExternalDependencyRule() : super(code: _code);

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

    final rules = config.dependencies.where((rule) {
      return rule.onIds.any((id) => component.id == id || component.id.startsWith('$id.'));
    }).toList();

    if (rules.isEmpty) return;

    final projectName = context.pubspec.name;

    // Helper: Is this URI external?
    bool isExternal(String uri) {
      if (uri.startsWith('dart:')) return true;
      if (uri.startsWith('package:')) {
        return !uri.startsWith('package:$projectName/');
      }
      return false;
    }

    // Helper: Validate the URI against rules
    void checkViolation(String uri, AstNode node) {
      for (final rule in rules) {
        // 1. Check Forbidden
        for (final pattern in rule.forbidden.imports) {
          if (PathMatcher.matches(uri, pattern)) {
            reporter.atNode(
              node,
              _code,
              arguments: [component.name ?? component.id, uri],
            );
            return;
          }
        }

        // 2. Check Allowed
        if (rule.allowed.imports.isNotEmpty) {
          bool isAllowed = false;
          for (final pattern in rule.allowed.imports) {
            if (PathMatcher.matches(uri, pattern)) {
              isAllowed = true;
              break;
            }
          }

          if (!isAllowed) {
            reporter.atNode(
              node,
              _code,
              arguments: [component.name ?? component.id, uri],
            );
          }
        }
      }
    }

    // 1. Check Imports
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;
      if (!isExternal(uri)) return;
      checkViolation(uri, node.uri);
    });

    // 2. Check Usages (Named Types)
    context.registry.addNamedType((node) {
      final element = node.element;
      if (element == null) return;

      final library = element.library;
      if (library == null) return;

      // Get the URI of the library where this type is defined
      final source = library.firstFragment.source;
      final uri = source.uri.toString();

      if (!isExternal(uri)) return;
      checkViolation(uri, node);
    });
  }
}
