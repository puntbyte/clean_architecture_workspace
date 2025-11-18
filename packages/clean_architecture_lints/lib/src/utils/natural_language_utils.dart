// lib/src/utils/natural_language_utils.dart

import 'package:dictionaryx/dictentry.dart';
import 'package:dictionaryx/dictionary_msa.dart';

/// A utility class for semantic linting using natural language processing.
/// It wraps a dictionary and uses caching and heuristics for performance.
class NaturalLanguageUtils {
  final DictionaryMSA? _dictionary;
  final Map<(POS, String), bool> _cache = {};
  final Map<String, Set<String>> _posOverrides;

  // Common words for fast lookups, avoiding dictionary access.
  static const _commonNouns = {
    'email',
    'profile',
    'data',
    'user',
    'state',
    'event',
    'auth',
    'dto',
    'request',
    'response',
  };
  static const _commonVerbs = {
    'get',
    'set',
    'fetch',
    'send',
    'save',
    'delete',
    'update',
    'load',
    'login',
    'logout',
  };
  static const _commonIrregularPastVerbs = {
    'went',
    'saw',
    'did',
    'took',
    'said',
    'came',
    'gave',
    'ran',
    'ate',
    'wrote',
    'was',
    'were',
    'had',
    'knew',
    'put',
    'thought',
    'became',
    'showed',
    'sent',
    'found',
    'built',
    'began',
    'left',
  };

  /// Creates an instance.
  /// - If [dictionary] is null, dictionary lookups are disabled (for tests).
  /// - [posOverrides] maps lowercase words to a set of POS names (e.g., {'get': {'VERB'}}).
  NaturalLanguageUtils({DictionaryMSA? dictionary, Map<String, Set<String>>? posOverrides})
    : _dictionary = dictionary,
      _posOverrides = posOverrides ?? {};

  void clearCache() => _cache.clear();

  int get cacheSize => _cache.length;

  bool isVerb(String word) => _hasPos(word, POS.VERB);

  bool isNoun(String word) => _hasPos(word, POS.NOUN);

  bool isAdjective(String word) => _hasPos(word, POS.ADJ);

  /// Checks if a [word] has a specific part-of-speech [pos], using a cache.
  bool _hasPos(String word, POS pos) {
    final lowerWord = word.toLowerCase();
    final cacheKey = (pos, lowerWord);
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    // Tier 1: User-defined overrides (for testing and customization).
    final override = _posOverrides[lowerWord];
    if (override != null) {
      return _cache[cacheKey] = override.contains(pos.name);
    }

    // Tier 2: Hardcoded common word lists for performance.
    if (pos == POS.NOUN && _commonNouns.contains(lowerWord)) return _cache[cacheKey] = true;
    if (pos == POS.VERB && _commonVerbs.contains(lowerWord)) return _cache[cacheKey] = true;

    // Tier 3: Dictionary lookup (if provided).
    if (_dictionary != null) {
      try {
        final entry = _dictionary.getEntry(lowerWord);
        final result = entry.meanings.any((m) => m.pos == pos);
        return _cache[cacheKey] = result;
      } catch (_) {
        // Word not found or other dictionary error.
      }
    }

    // Default to false if no match was found.
    return _cache[cacheKey] = false;
  }

  /// Heuristic to determine if a word is a verb gerund (ending in "-ing").
  bool isVerbGerund(String word) {
    final lowerWord = word.toLowerCase();
    if (!lowerWord.endsWith('ing') || lowerWord.length < 4) return false;

    // Rule 1: Prioritize nouns. If a word is a known noun but not a verb (e.g., "Building"),
    // it should not be considered a verb gerund for our naming rules.
    if (isNoun(word) && !isVerb(word)) {
      return false;
    }

    // Rule 2: If the word itself is a known verb, it's valid.
    if (isVerb(word)) return true;

    // Rule 3: Check the verb stem.
    final stem = lowerWord.substring(0, lowerWord.length - 3);

    // Case: doubling consonant (e.g., "getting" -> "gett" -> "get")
    if (stem.length > 1 && stem.endsWith(stem[stem.length - 1])) {
      final base = stem.substring(0, stem.length - 1);
      if (isVerb(base) || isVerb('${base}e')) return true;
    }

    // Case: dropped 'e' (e.g., "updating" -> "updat" -> "update")
    return isVerb(stem) || isVerb('${stem}e');
  }

  /// Heuristic to determine if a word is a past-tense verb.
  bool isVerbPast(String word) {
    // Rule 1: Prioritize adjectives. If a word is a known adjective but not a verb (e.g., "nested", "red"),
    // it should not be considered a past-tense verb.
    if (isAdjective(word) && !isVerb(word)) {
      return false;
    }

    final lowerWord = word.toLowerCase();

    // Rule 2: Check for common irregular past-tense verbs.
    if (_commonIrregularPastVerbs.contains(lowerWord)) return true;

    // Rule 3: Check for -ied ending (e.g., "applied" -> "apply").
    if (lowerWord.endsWith('ied') && lowerWord.length > 3) {
      final stem = lowerWord.substring(0, lowerWord.length - 3);
      if (isVerb('${stem}y')) return true;
    }

    // Rule 4: Check for -ed ending.
    if (lowerWord.endsWith('ed')) {
      final stem = lowerWord.substring(0, lowerWord.length - 2);
      if (stem.isEmpty) return false;

      // Case: doubling consonant (e.g., "stopped" -> "stopp" -> "stop")
      if (stem.length > 1 && stem.endsWith(stem[stem.length - 1])) {
        final base = stem.substring(0, stem.length - 1);
        if (isVerb(base)) return true;
      }

      // Case: dropped 'e' or regular (e.g., "updated" -> "updat" -> "update" or "requested" -> "request")
      if (isVerb(stem) || isVerb('${stem}e')) return true;
    }

    // Rule 5: Fallback for other irregulars that might be in the dictionary.
    return isVerb(word);
  }
}
