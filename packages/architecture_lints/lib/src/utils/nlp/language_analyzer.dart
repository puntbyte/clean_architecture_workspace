import 'package:architecture_lints/src/utils/nlp/nlp_constants.dart';
import 'package:dictionaryx/dictentry.dart';
import 'package:dictionaryx/dictionary_msa.dart';

class LanguageAnalyzer {
  final DictionaryMSA? _dictionary;

  // Simple cache to avoid repeated lookups for the same word
  final Map<String, Set<String>> _posCache = {};

  /// If true, the presence of a dictionary entry is treated as a weak signal
  /// that the token is a noun.
  final bool treatEntryAsNounIfExists;

  LanguageAnalyzer({
    DictionaryMSA? dictionary,
    this.treatEntryAsNounIfExists = true,
  }) : _dictionary = dictionary;

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
    if (!lower.endsWith('s')) return false;
    if (singularNounExceptions.contains(lower)) return false;
    if (irregularPlurals.containsKey(lower)) return true;

    // Simple morphology
    if (lower.endsWith('ies')) return _hasPos('${lower.substring(0, lower.length - 3)}y', POS.NOUN);
    if (lower.endsWith('es')) return _hasPos(lower.substring(0, lower.length - 2), POS.NOUN);

    return _hasPos(lower.substring(0, lower.length - 1), POS.NOUN);
  }

  bool isNounSingular(String word) => isNoun(word) && !isNounPlural(word);

  bool isVerb(String word) => _hasPos(word, POS.VERB);

  bool isVerbGerund(String word) {
    final lower = word.toLowerCase();
    if (!lower.endsWith('ing')) return false;
    // Strip 'ing' and check if base is verb (handling simple doubling like 'getting' -> 'get')
    final stem = lower.substring(0, lower.length - 3);
    return isVerb(stem) || isVerb('${stem}e');
  }

  bool isVerbPast(String word) {
    final lower = word.toLowerCase();
    if (irregularPastVerbs.containsKey(lower)) return true;
    if (lower.endsWith('ed')) {
      final stem = lower.substring(0, lower.length - 2);
      return isVerb(stem) || isVerb('${stem}e');
    }
    return isVerb(word); // Some past tenses look like base (put -> put)
  }

  bool _hasPos(String word, POS pos) {
    final lower = word.toLowerCase();

    // 1. Fast Path (Constants)
    if (pos == POS.NOUN && commonNouns.contains(lower)) return true;
    if (pos == POS.VERB && commonVerbs.contains(lower)) return true;
    if (pos == POS.ADV && commonAdverbs.contains(lower)) return true;

    // 2. Dictionary Lookup
    if (_dictionary != null) {
      if (_checkDictionary(lower, pos)) return true;
    }

    return false;
  }

  bool _checkDictionary(String word, POS pos) {
    try {
      // Logic from DictionaryX
      final hasEntry = _dictionary!.hasEntry(word);
      if (!hasEntry) return false;

      final entry = _dictionary!.getEntry(word);
      if (entry.meanings.any((m) => m.pos == pos)) return true;

      // Weak signal fallback
      if (treatEntryAsNounIfExists && pos == POS.NOUN) return true;
    } catch (_) {}
    return false;
  }
}