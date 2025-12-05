import 'package:collection/collection.dart';

enum GrammarToken {
  noun('{{noun}}', 'a Noun'),
  nounPhrase('{{noun.phrase}}', 'a Noun Phrase'),
  nounSingular('{{noun.singular}}', 'a Singular Noun'),
  nounPlural('{{noun.plural}}', 'a Plural Noun'),

  verb('{{verb}}', 'a Verb'),
  verbPresent('{{verb.present}}', 'a Present Tense Verb'),
  verbPast('{{verb.past}}', 'a Past Tense Verb'),
  verbGerund('{{verb.gerund}}', 'a Gerund (action ending in -ing)'),

  adjective('{{adjective}}', 'an Adjective')
  ;

  final String template;
  final String description;

  const GrammarToken(this.template, this.description);

  static GrammarToken? fromString(String template) {
    return GrammarToken.values.firstWhereOrNull((e) => e.template == template);
  }

  /// Checks if a config string contains this token
  bool isPresentIn(String configString) {
    return configString.contains(template);
  }
}
