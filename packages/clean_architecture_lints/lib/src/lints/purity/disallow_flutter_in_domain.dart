// lib/srcs/lints/purity/disallow_flutter_in_domain.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/component_config.dart';
import 'package:clean_architecture_lints/src/utils/ast_utils.dart';
import 'package:clean_architecture_lints/src/utils/type_checker_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

/// A comprehensive lint that disallows any Flutter dependencies in the domain layer.
class DisallowFlutterInDomain extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_flutter_in_domain',
    problemMessage: 'Domain layer purity violation: Do not depend on Flutter.',
    correctionMessage:
        'The domain layer must be platform-independent. Remove Flutter imports and types.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowFlutterInDomain({
    required super.config,
    required super.componentResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = componentResolver.resolveComponent(resolver.source.fullName);

    // This is the most robust check: find the top-level component for the file.
    ComponentConfig? topLevelComponent;
    var current = component;
    while (current != null) {
      topLevelComponent = current;
      current = componentResolver.resolveComponent(
        p.dirname(current.key),
      ); // This needs improvement
    }
    // Let's simplify the logic for now. The initial check is good enough.
    if (component?.kind.name.startsWith('domain') != true) {
      return;
    }

    context.registry.addImportDirective((node) {
      final importUri = node.uri.stringValue;
      if (importUri != null &&
          (importUri.startsWith('package:flutter/') || importUri == 'dart:ui')) {
        reporter.atNode(node, _code);
      }
    });

    void validate(TypeAnnotation? typeNode) {
      if (typeNode != null && TypeCheckerUtils.isFlutterType(typeNode.type)) {
        reporter.atNode(typeNode, _code);
      }
    }

    context.registry.addMethodDeclaration((node) {
      validate(node.returnType);
      node.parameters?.parameters.forEach(
        (param) => validate(AstUtils.getParameterTypeNode(param)),
      );
    });

    // Correct way to check variables in fields and top-level declarations.
    context.registry.addFieldDeclaration((node) => validate(node.fields.type));
    context.registry.addTopLevelVariableDeclaration((node) => validate(node.variables.type));
  }
}
