import 'package:architecture_lints/src/schema/enums/grammar_token.dart';
import 'package:architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:architecture_lints/src/engines/language/language_analyzer.dart';

mixin GrammarLogic {
  /// Validates [className] against a [grammar] string using the [analyzer].
  GrammarResult validateGrammar(String grammar, String className, LanguageAnalyzer analyzer) {
    final coreName = _extractCoreName(grammar, className);
    if (coreName.isEmpty) return const GrammarResult.valid();

    final words = coreName.splitPascalCase();
    if (words.isEmpty) return const GrammarResult.valid();

    // --- PRIORITY 1: ACTIONS (Verb-Noun) ---
    // Triggered if grammar explicitly asks for a base Verb (e.g. GetUser)
    if (GrammarToken.verb.isPresentIn(grammar) || GrammarToken.verbPresent.isPresentIn(grammar)) {
      if (words.length < 2) {
        return const GrammarResult.invalid(
          reason: 'The name is too short.',
          correction: 'Use the format Action + Subject (e.g., GetUser).',
        );
      }

      final firstWord = words.first;
      if (!analyzer.isVerb(firstWord)) {
        return GrammarResult.invalid(
          reason: 'The first word "$firstWord" is not a recognized Verb.',
          correction: 'Start with an action verb like Get, Save, or Load.',
        );
      }

      final lastWord = words.last;
      if (!analyzer.isNoun(lastWord)) {
        return GrammarResult.invalid(
          reason: 'The last word "$lastWord" is not a recognized Noun (Subject).',
          correction: 'End with the subject being acted upon (e.g., User, Data).',
        );
      }
      return const GrammarResult.valid();
    }

    // --- PRIORITY 2: STATES (Adjective/Past/Gerund) ---
    // Triggered if grammar asks for state descriptors
    if (GrammarToken.adjective.isPresentIn(grammar) ||
        GrammarToken.verbGerund.isPresentIn(grammar) ||
        GrammarToken.verbPast.isPresentIn(grammar)) {
      final last = words.last;
      var match = false;

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

    // --- PRIORITY 3: OBJECTS (Noun Phrases) ---
    // Fallback for Entities, Models, etc.
    if (GrammarToken.noun.isPresentIn(grammar) ||
        GrammarToken.nounPhrase.isPresentIn(grammar) ||
        GrammarToken.nounSingular.isPresentIn(grammar) ||
        GrammarToken.nounPlural.isPresentIn(grammar)) {
      final head = words.last;

      // A. Strict POS Check on Head Noun
      if (!analyzer.isNoun(head)) {
        // Allow fallback if word is unknown, but flag if it's definitely a verb
        if (analyzer.isVerb(head)) {
          return GrammarResult.invalid(
            reason: 'The subject "$head" seems to be a Verb (Action).',
            correction: 'Ensure the name describes a specific Object.',
          );
        }
      }

      // B. Plurality Check
      if (GrammarToken.nounPlural.isPresentIn(grammar) && !analyzer.isNounPlural(head)) {
        return const GrammarResult.invalid(
          reason: 'Subject is not a Plural Noun.',
          correction: 'Use a plural noun.',
        );
      }
      if (GrammarToken.nounSingular.isPresentIn(grammar) && !analyzer.isNounSingular(head)) {
        return const GrammarResult.invalid(
          reason: 'Subject is not a Singular Noun.',
          correction: 'Use a singular noun.',
        );
      }

      // C. Modifier Check (No Verbs/Gerunds allowed in Noun Phrases)
      for (var i = 0; i < words.length - 1; i++) {
        final word = words[i];
        if (analyzer.isVerbGerund(word)) {
          return GrammarResult.invalid(
            reason: '"$word" is a Gerund (action), but this component should be a static Noun.',
            correction: 'Remove "$word" or change it to a descriptive adjective.',
          );
        }
      }
      return const GrammarResult.valid();
    }

    return const GrammarResult.valid();
  }

  String _extractCoreName(String grammar, String className) {
    var regexStr = RegExp.escape(grammar);

    for (final token in GrammarToken.values) {
      final escapedTemplate = RegExp.escape(token.template);
      // Use non-greedy match for parts before the last token, greedy for the rest?
      // Simple (.*) usually works if structure is simple Prefix${token}Suffix
      regexStr = regexStr.replaceAll(escapedTemplate, '(.*)');
    }

    final regex = RegExp('^$regexStr\$');
    final match = regex.firstMatch(className);

    if (match != null) {
      final buffer = StringBuffer();
      for (var i = 1; i <= match.groupCount; i++) {
        buffer.write(match.group(i) ?? '');
      }
      return buffer.toString();
    }
    return className;
  }
}

class GrammarResult {
  final bool isValid;
  final String? reason;
  final String? correction;

  const GrammarResult.valid() : isValid = true, reason = null, correction = null;

  const GrammarResult.invalid({
    required this.reason,
    required this.correction,
  }) : isValid = false;
}
