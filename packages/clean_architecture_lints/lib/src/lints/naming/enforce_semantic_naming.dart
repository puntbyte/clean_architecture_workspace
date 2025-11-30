// lib/src/lints/naming/enforce_semantic_naming.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/language_analyzer.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceSemanticNaming extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_semantic_naming',
    problemMessage: 'The {2} name "{0}" is grammatically incorrect: {1}',
    correctionMessage:
        'Rename the class to satisfy the grammar rule (e.g., use Nouns for Entities, Verb-Noun for UseCases).',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final LanguageAnalyzer analyzer;

  const EnforceSemanticNaming({
    required super.config,
    required super.layerResolver,
    required this.analyzer,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;

      final component = layerResolver.getComponent(resolver.source.fullName, className: className);
      if (component == ArchComponent.unknown) return;

      final rule = config.namingConventions.ruleFor(component);
      final grammar = rule?.grammar;
      if (grammar == null || grammar.isEmpty) return;

      final validator = _GrammarValidator(grammar, analyzer, component.label);
      final result = validator.validate(className);

      if (!result.isValid) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [
            className,
            result.message ?? 'Structure check failed',
            component.label,
          ],
        );
      }
    });
  }
}

class _ValidationResult {
  final bool isValid;
  final String? message;

  const _ValidationResult.valid() : isValid = true, message = null;

  const _ValidationResult.invalid(this.message) : isValid = false;
}

class _GrammarValidator {
  final String grammar;
  final LanguageAnalyzer nlp;
  final String componentLabel;

  _GrammarValidator(this.grammar, this.nlp, this.componentLabel);

  _ValidationResult validate(String className) {
    final words = className.splitPascalCase();
    if (words.isEmpty) return const _ValidationResult.valid();

    // --- 1. UseCase: Verb + Noun ---
    if (grammar == '{{verb.present}}{{noun.phrase}}') {
      if (words.length < 2) {
        return const _ValidationResult.invalid(
          'Name is too short. Expected "ActionSubject" (e.g. GetUser).',
        );
      }
      if (!nlp.isVerb(words.first)) {
        return _ValidationResult.invalid(
          'Must start with an action (Verb). "${words.first}" is [${_identifyPOS(words.first)}].',
        );
      }
      if (!nlp.isNoun(words.last)) {
        return _ValidationResult.invalid(
          'Must end with a subject (Noun). "${words.last}" is [${_identifyPOS(words.last)}].',
        );
      }
      return const _ValidationResult.valid();
    }

    // --- 2. Noun Phrases (Singular, Plural, or Any) ---
    if (grammar.startsWith('{{noun.')) {
      final tokenEndIndex = grammar.indexOf('}}');
      if (tokenEndIndex == -1) return const _ValidationResult.valid();

      final token = grammar.substring(2, tokenEndIndex);
      final suffix = grammar.substring(tokenEndIndex + 2);

      // FIX: If the name doesn't end with the required suffix, we skip checking semantics.
      // The `enforce_naming_pattern` lint is responsible for enforcing the suffix.
      if (suffix.isNotEmpty && !className.endsWith(suffix)) {
        return const _ValidationResult.valid();
      }

      // Extract the base name to check its grammar
      final baseName = suffix.isNotEmpty
          ? className.substring(0, className.length - suffix.length)
          : className;

      final baseWords = baseName.splitPascalCase();
      if (baseWords.isEmpty) return const _ValidationResult.valid();

      final lastWord = baseWords.last;

      if (token == 'noun.plural') {
        if (!nlp.isNounPlural(lastWord)) {
          return _ValidationResult.invalid(
            'The subject "$lastWord" must be a Plural Noun. Currently identified as [${_identifyPOS(lastWord)}].',
          );
        }
      } else if (token == 'noun.singular') {
        if (!nlp.isNounSingular(lastWord)) {
          return _ValidationResult.invalid(
            'The subject "$lastWord" must be a Singular Noun. Currently identified as [${_identifyPOS(lastWord)}].',
          );
        }
      } else {
        if (!nlp.isNoun(lastWord)) {
          return _ValidationResult.invalid(
            'The subject "$lastWord" must be a Noun. Currently identified as [${_identifyPOS(lastWord)}].',
          );
        }
      }

      for (final word in baseWords) {
        final isStrictVerb = nlp.isVerb(word) && !nlp.isNoun(word);
        final isGerund = nlp.isVerbGerund(word);
        if (isStrictVerb || isGerund) {
          return _ValidationResult.invalid(
            'It contains "$word" (identified as [${_identifyPOS(word)}]), which implies an action/verb.',
          );
        }
      }

      return const _ValidationResult.valid();
    }

    // --- 3. State Grammar ---
    if (grammar.contains('{{adjective}}|{{verb.gerund}}|{{verb.past}}')) {
      if (words.length < 2) return const _ValidationResult.invalid('Name too short for a State.');
      final lastWord = words.last;
      final isValid =
          nlp.isAdjective(lastWord) ||
          nlp.isVerbGerund(lastWord) ||
          nlp.isVerbPast(lastWord) ||
          nlp.isNoun(lastWord);

      if (!isValid) {
        return _ValidationResult.invalid(
          'Suffix "$lastWord" is [${_identifyPOS(lastWord)}], but a state description is expected.',
        );
      }
      return const _ValidationResult.valid();
    }

    return const _ValidationResult.valid();
  }

  String _identifyPOS(String word) {
    final types = <String>[];
    if (nlp.isNounSingular(word)) types.add('Singular Noun');
    if (nlp.isNounPlural(word)) types.add('Plural Noun');
    if (types.isEmpty && nlp.isNoun(word)) types.add('Noun');

    if (nlp.isVerb(word) && !word.toLowerCase().endsWith('ed')) types.add('Verb');
    if (nlp.isAdjective(word)) types.add('Adjective');
    if (nlp.isVerbGerund(word)) types.add('Gerund');

    if (types.isEmpty) return 'Unknown';
    return types.join(' & ');
  }
}
