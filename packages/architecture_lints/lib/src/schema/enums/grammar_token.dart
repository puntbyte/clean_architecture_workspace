import 'package:architecture_lints/src/utils/token_syntax.dart';
import 'package:collection/collection.dart';

enum GrammarToken {
  // Nouns
  noun('a Noun'),
  nounPhrase('a Noun Phrase'),
  nounSingular('a Singular Noun'),
  nounPlural('a Plural Noun'),

  // Verbs
  verb('a Verb'),
  verbPresent('a Present Tense Verb'),
  verbPast('a Past Tense Verb'),
  verbGerund('a Gerund (action ending in -ing)'),

  // Other
  adjective('an Adjective'),
  adverb('an Adverb'),
  conjunction('a Conjunction'),
  preposition('a Preposition'),
  ;

  final String description;

  const GrammarToken(this.description);

  static GrammarToken? fromString(String template) =>
      GrammarToken.values.firstWhereOrNull((token) => token.template == template);

  String get template => switch (this) {
    GrammarToken.noun => TokenSyntax.wrap('noun'),
    GrammarToken.nounPhrase => TokenSyntax.wrap('noun.phrase'),
    GrammarToken.nounSingular => TokenSyntax.wrap('noun.singular'),
    GrammarToken.nounPlural => TokenSyntax.wrap('noun.plural'),

    GrammarToken.verb => TokenSyntax.wrap('verb'),
    GrammarToken.verbPresent => TokenSyntax.wrap('verb.present'),
    GrammarToken.verbPast => TokenSyntax.wrap('verb.past'),
    GrammarToken.verbGerund => TokenSyntax.wrap('verb.gerund'),

    GrammarToken.adjective => TokenSyntax.wrap('adjective'),
    GrammarToken.adverb => TokenSyntax.wrap('adverb'),
    GrammarToken.conjunction => TokenSyntax.wrap('conjunction'),
    GrammarToken.preposition => TokenSyntax.wrap('preposition'),
  };

  /// Checks if a config string contains this token
  bool isPresentIn(String configString) => configString.contains(template);
}
