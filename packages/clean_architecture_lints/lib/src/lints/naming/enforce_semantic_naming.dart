// lib/srcs/lints/naming/enforce_semantic_naming.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:clean_architecture_lints/src/utils/natural_language_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes follow the semantic naming conventions (`grammar`).
class EnforceSemanticNaming extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_semantic_naming',
    problemMessage: 'The name `{0}` does not follow the required grammatical structure for a {1}.',
  );

  final NaturalLanguageUtils nlpUtils;

  const EnforceSemanticNaming({
    required super.config,
    required super.layerResolver,
    required this.nlpUtils,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    context.registry.addClassDeclaration((node) async { // ASYNC
      final filePath = resolver.source.fullName;
      final className = node.name.lexeme;

      // Determine the precise component type for this class.
      final component = layerResolver.getComponent(filePath, className: className);
      if (component == ArchComponent.unknown) return;

      // Get the specific naming rule for this component.
      final rule = config.namingConventions.getRuleFor(component);

      // Only proceed if a grammar rule is defined for this component.
      final grammar = rule?.grammar;
      if (grammar != null || grammar!.isEmpty) return;

      final validator = _GrammarValidator(grammar, nlpUtils);
      final isValid = await validator.isValid(className, node);

      if (!isValid) {
        reporter.atToken(
          node.name,
          LintCode(
            name: _code.name,
            problemMessage: 'The name `$className` does not follow the grammatical structure '
                '`$grammar` for a ${component.label}.',
          ),
        );
      }
    });
  }
}


/// A private helper class for parsing and validating a grammar pattern.
class _GrammarValidator {
  final String grammar;
  final NaturalLanguageUtils nlp;
  _GrammarValidator(this.grammar, this.nlp);

  Future<bool> isValid(String className, ClassDeclaration node) async {
    final words = className.splitPascalCase();
    if (words.isEmpty) return false;

    // This is a placeholder for a true grammar parser. For now, it handles
    // the most common `use_case` grammar. A full implementation would be a
    // recursive descent parser for your grammar syntax.
    if (grammar == '{{verb.present}}{{noun.phrase}}') {
      if (words.length < 2) return false;
      final isVerb = nlp.isVerb(words.first);
      final isNoun = nlp.isNoun(words.last);
      return isVerb && isNoun;
    }

    // Default to true if the grammar is not yet supported by this simple parser.
    return true;
  }
}
