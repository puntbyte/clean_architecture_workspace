import 'package:architecture_lints/src/config/constants/grammar_token.dart';
import 'package:architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:architecture_lints/src/utils/nlp/language_analyzer.dart';

class GrammarResult {
  final bool isValid;
  final String? reason;
  final String? correction;

  const GrammarResult.valid() : isValid = true, reason = null, correction = null;

  const GrammarResult.invalid({required this.reason, required this.correction}) : isValid = false;
}

mixin GrammarLogic {
  /// Validates [className] against a [grammar] string using the [analyzer].
  GrammarResult validateGrammar(String grammar, String className, LanguageAnalyzer analyzer) {
    // 1. Extract Core Name (Strip structural suffixes if they explicitly match)
    // e.g. Grammar: {{noun}}Model, Class: UserModel -> Core: User
    String coreName = className;
    final startPlaceholder = grammar.indexOf('{{');
    final endPlaceholder = grammar.lastIndexOf('}}');

    if (startPlaceholder != -1 && endPlaceholder != -1) {
      final prefix = grammar.substring(0, startPlaceholder);
      final suffix = grammar.substring(endPlaceholder + 2);

      if (className.startsWith(prefix) && className.endsWith(suffix)) {
        coreName = className.substring(prefix.length, className.length - suffix.length);
      }
    }

    final words = coreName.splitPascalCase();
    if (words.isEmpty) return const GrammarResult.valid();

    // --- CASE 1: Verb-Noun (UseCase) ---
    if (GrammarToken.verb.isPresentIn(grammar) && GrammarToken.noun.isPresentIn(grammar)) {
      if (words.length < 2) {
        return const GrammarResult.invalid(
          reason: 'The name is too short.',
          correction: 'Use the format Action + Subject (e.g., GetUser).',
        );
      }

      if (!analyzer.isVerb(words.first)) {
        return GrammarResult.invalid(
          reason: 'The first word "${words.first}" is not a recognized Verb (Action).',
          correction: 'Start with an action verb like Get, Save, or Load.',
        );
      }
      if (!analyzer.isNoun(words.last)) {
        return GrammarResult.invalid(
          reason: 'The last word "${words.last}" is not a recognized Noun (Subject).',
          correction: 'End with the subject being acted upon (e.g., User, Data).',
        );
      }
      return const GrammarResult.valid();
    }

    // --- CASE 2: Noun Phrase (Entity, Model) ---
    if (GrammarToken.noun.isPresentIn(grammar) || GrammarToken.nounPhrase.isPresentIn(grammar)) {
      final head = words.last;

      // Strict POS Check based on specific tokens
      if (!analyzer.isNoun(head)) {
        String specific = 'Noun';
        if (GrammarToken.nounPlural.isPresentIn(grammar) && !analyzer.isNounPlural(head)) {
          return GrammarResult.invalid(
            reason: '"$head" is not a Plural Noun.',
            correction: 'Use a plural noun.',
          );
        }
        if (GrammarToken.nounSingular.isPresentIn(grammar) && !analyzer.isNounSingular(head)) {
          return GrammarResult.invalid(
            reason: '"$head" is not a Singular Noun.',
            correction: 'Use a singular noun.',
          );
        }
        if (!analyzer.isNoun(head)) {
          return GrammarResult.invalid(
            reason: 'The subject "$head" is not a recognized Noun.',
            correction: 'Ensure the name describes a specific Object, not an action.',
          );
        }
      }

      // Modifier Check (No Verbs/Gerunds allowed in Noun Phrases)
      for (int i = 0; i < words.length - 1; i++) {
        final word = words[i];
        if (analyzer.isVerbGerund(word)) {
          return GrammarResult.invalid(
            reason: '"$word" is a Gerund (action), but this component should be a static Noun.',
            correction: 'Remove "$word" or change it to a descriptive adjective.',
          );
        }
        // Strict Verb check (skipping ambiguous words)
        if (analyzer.isVerb(word) && !analyzer.isNoun(word)) {
          return GrammarResult.invalid(
            reason: '"$word" implies an action.',
            correction: 'Remove the action verb.',
          );
        }
      }
      return const GrammarResult.valid();
    }

    // --- CASE 3: State (Adjective/Past/Gerund) ---
    if (GrammarToken.adjective.isPresentIn(grammar) ||
        GrammarToken.verbGerund.isPresentIn(grammar) ||
        GrammarToken.verbPast.isPresentIn(grammar)) {
      final last = words.last;
      bool match = false;

      if (GrammarToken.adjective.isPresentIn(grammar) && analyzer.isAdjective(last)) match = true;
      if (GrammarToken.verbGerund.isPresentIn(grammar) && analyzer.isVerbGerund(last)) match = true;
      if (GrammarToken.verbPast.isPresentIn(grammar) && analyzer.isVerbPast(last)) match = true;

      if (!match) {
        return GrammarResult.invalid(
          reason: 'The suffix "$last" does not describe a valid State.',
          correction: 'States should end with an Adjective, Past Action, or Ongoing Action.',
        );
      }
      return const GrammarResult.valid();
    }

    return const GrammarResult.valid();
  }
}
