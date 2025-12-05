import 'package:architecture_lints/src/config/schema/component_config.dart';

class MessageUtils {
  const MessageUtils._();

  /// Converts 'domain.usecase' -> 'Domain UseCase'.
  static String humanizeComponent(ComponentConfig component) {
    if (component.name != null) return component.name!;

    // Fallback: Capitalize ID segments
    return component.id
        .split('.')
        .map((s) => s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}')
        .join(' ');
  }

  /// Converts '{{verb.past}}' -> 'Past Tense Verb'.
  static String humanizeGrammarToken(String token) {
    switch (token) {
      case '{{noun}}':
      case '{{noun.phrase}}':
        return 'a Noun Phrase (a thing/object)';
      case '{{noun.singular}}':
        return 'a Singular Noun';
      case '{{noun.plural}}':
        return 'a Plural Noun';
      case '{{verb}}':
      case '{{verb.present}}':
        return 'a Verb (an action)';
      case '{{verb.past}}':
        return 'a Past Tense Verb (something happened)';
      case '{{verb.gerund}}':
        return 'a Gerund (an ongoing action ending in -ing)';
      case '{{adjective}}':
        return 'an Adjective (descriptive)';
      default:
        return token; // Fallback
    }
  }

  /// Generates a friendly example based on a pattern.
  /// '{{name}}UseCase' -> 'LoginUseCase'
  static String generateExample(String pattern) {
    return pattern
        .replaceAll('{{name}}', 'Login')
        .replaceAll('{{affix}}', 'My');
  }
}