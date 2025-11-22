// lib/src/lints/naming/enforce_semantic_naming.dart

import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/natural_language_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes follow the semantic naming conventions (`grammar`).
class EnforceSemanticNaming extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_semantic_naming',
    problemMessage: 'The name `{0}` does not follow the grammatical structure `{1}` for a {2}.',
  );

  final NaturalLanguageUtils nlpUtils;

  const EnforceSemanticNaming({
    required super.config,
    required super.layerResolver,
    required this.nlpUtils,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;

      // 1. Identify component
      final component = layerResolver.getComponent(resolver.source.fullName, className: className);
      if (component == ArchComponent.unknown) return;

      // 2. Get Rule
      final rule = config.namingConventions.getRuleFor(component);
      final grammar = rule?.grammar;
      if (grammar == null || grammar.isEmpty) return;

      // 3. Validate
      final validator = _GrammarValidator(grammar, nlpUtils);
      if (!validator.isValid(className)) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [className, grammar, component.label],
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

  bool isValid(String className) {
    final words = className.splitPascalCase();
    if (words.isEmpty) return false;

    // --- Heuristic-based Grammar Parsing ---

    // Case 1: {{verb.present}}{{noun.phrase}} (e.g., Usecases)
    if (grammar == '{{verb.present}}{{noun.phrase}}') {
      if (words.length < 2) return false;
      return nlp.isVerb(words.first) && nlp.isNoun(words.last);
    }

    // Case 2: {{noun.phrase}}SomeSuffix (e.g., Models, Managers)
    if (grammar.startsWith('{{noun.phrase}}')) {
      final suffix = grammar.substring('{{noun.phrase}}'.length);
      // It's possible for the suffix to be empty if the grammar is just {{noun.phrase}}
      if (suffix.isNotEmpty && !className.endsWith(suffix)) return false;

      final baseName = suffix.isNotEmpty
          ? className.substring(0, className.length - suffix.length)
          : className;

      final baseWords = baseName.splitPascalCase();
      if (baseWords.isEmpty) return false;

      // A noun phrase should end with a noun and should NOT act like a verb phrase.
      // e.g. "FetchUserModel" -> Fetch (Verb) User (Noun) -> Invalid Noun Phrase.
      final endsWithNoun = nlp.isNoun(baseWords.last);
      final containsNoVerbs = !baseWords.any(nlp.isVerb);

      return endsWithNoun && containsNoVerbs;
    }

    // Case 3: {{subject}}({{adjective}}|{{verb.gerund}}|{{verb.past}}) (e.g., States)
    if (grammar.contains('{{adjective}}|{{verb.gerund}}|{{verb.past}}')) {
      if (words.length < 2) return false;
      final lastWord = words.last;
      return nlp.isAdjective(lastWord) || nlp.isVerbGerund(lastWord) || nlp.isVerbPast(lastWord);
    }

    // Default to true if the grammar is not yet supported by our heuristics.
    return true;
  }
}