import 'package:architecture_lints/src/config/schema/vocabulary_config.dart';
import 'package:architecture_lints/src/utils/nlp/nlp_constants.dart';
import 'package:dictionaryx/dictentry.dart';
import 'package:dictionaryx/dictionary_msa.dart';

class LanguageAnalyzer {
  /// Static instance shared across all analyzer instances to avoid reloading memory.
  static final DictionaryMSA _sharedDictionary = DictionaryMSA();

  final DictionaryMSA? _dictionary;
  final VocabularyConfig _overrides;
  final bool treatEntryAsNounIfExists;

  LanguageAnalyzer({
    DictionaryMSA? dictionary,
    VocabularyConfig? vocabulary,
    this.treatEntryAsNounIfExists = true,
  }) : _dictionary = dictionary ?? _sharedDictionary,
       _overrides = vocabulary ?? const VocabularyConfig();

  bool isAdjective(String word) => _hasPos(word, POS.ADJ);

  bool isAdverb(String word) {
    final lower = word.toLowerCase();
    if (_hasPos(lower, POS.ADV)) return true;
    if (lower.endsWith('ly') && !commonNouns.contains(lower)) return true;
    return commonAdverbs.contains(lower);
  }

  bool isNoun(String word) {
    if (_hasPos(word, POS.NOUN)) return true;
    return isNounPlural(word);
  }

  bool isNounPlural(String word) {
    final lower = word.toLowerCase();
    // Check override first (e.g. 'stats' -> noun)
    if (_overrides.nouns.contains(lower)) return true;

    if (!lower.endsWith('s')) return false;
    if (singularNounExceptions.contains(lower)) return false;
    if (irregularPlurals.containsKey(lower)) return true;

    if (lower.endsWith('ies')) return _hasPos('${lower.substring(0, lower.length - 3)}y', POS.NOUN);
    if (lower.endsWith('es')) return _hasPos(lower.substring(0, lower.length - 2), POS.NOUN);

    return _hasPos(lower.substring(0, lower.length - 1), POS.NOUN);
  }

  bool isNounSingular(String word) => isNoun(word) && !isNounPlural(word);

  bool isVerb(String word) => _hasPos(word, POS.VERB);

  bool isVerbGerund(String word) {
    final lower = word.toLowerCase();
    // Override check: if user says "MyThing" is a noun, it's not a gerund even if it ends in ing.
    if (_overrides.nouns.contains(lower)) return false;
    if (_overrides.verbs.contains(lower)) return true;

    if (!lower.endsWith('ing')) return false;
    final stem = lower.substring(0, lower.length - 3);
    return isVerb(stem) || isVerb('${stem}e');
  }

  bool isVerbPast(String word) {
    final lower = word.toLowerCase();
    if (_overrides.verbs.contains(lower)) return true;

    if (irregularPastVerbs.containsKey(lower)) return true;
    if (lower.endsWith('ed')) {
      final stem = lower.substring(0, lower.length - 2);
      return isVerb(stem) || isVerb('${stem}e');
    }
    return isVerb(word);
  }

  bool _hasPos(String word, POS pos) {
    final lower = word.toLowerCase();

    // 1. Vocabulary Overrides (Highest Priority)
    if (pos == POS.NOUN && _overrides.nouns.contains(lower)) return true;
    if (pos == POS.VERB && _overrides.verbs.contains(lower)) return true;
    if (pos == POS.ADJ && _overrides.adjectives.contains(lower)) return true;

    // 2. Fast Path (Constants)
    if (pos == POS.NOUN && commonNouns.contains(lower)) return true;
    if (pos == POS.VERB && commonVerbs.contains(lower)) return true;
    if (pos == POS.ADV && commonAdverbs.contains(lower)) return true;

    // 3. Dictionary Lookup
    if (_dictionary != null) {
      if (_checkDictionary(lower, pos)) return true;
    }

    return false;
  }

  bool _checkDictionary(String word, POS pos) {
    try {
      final hasEntry = _dictionary!.hasEntry(word);
      if (!hasEntry) return false;

      final entry = _dictionary.getEntry(word);
      if (entry.meanings.any((m) => m.pos == pos)) return true;

      // Weak signal fallback
      if (treatEntryAsNounIfExists && pos == POS.NOUN) return true;
    } catch (_) {}
    return false;
  }
}
