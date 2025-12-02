// lib/src/utils/nlp/language_analyzer.dart

import 'package:architecture_lints/src/utils/nlp/cache.dart';
import 'package:architecture_lints/src/utils/nlp/constants.dart';
import 'package:dictionaryx/dictentry.dart';
import 'package:dictionaryx/dictionary_msa.dart';

/// Synchronous NaturalLanguageProcessor for use with DictionarySA.
///
/// It uses a tiered lookup strategy:
/// 1. **Overrides**: User-defined mappings (fastest).
/// 2. **Common Constants**: Hardcoded lists of common dev terminology (fast).
/// 3. **Heuristics**: String suffix logic for plurals, gerunds, etc.
/// 4. **Dictionary**: Full English dictionary lookup (slowest, optional).
class LanguageAnalyzer {
  final DictionaryMSA? _dictionary;
  final Map<CacheKey, CacheValue<bool>> _cache = {};
  final Map<String, Set<String>> posOverrides;
  final Duration? cacheTtl;

  /// If true, the presence of a dictionary entry (hasEntry) is treated as a
  /// weak signal that the token is a noun. Default: true.
  final bool treatEntryAsNounIfExists;

  LanguageAnalyzer({
    DictionaryMSA? dictionary,
    Map<String, Set<String>>? posOverrides,
    this.cacheTtl,
    bool? treatEntryAsNounIfExists,
  }) : _dictionary = dictionary,
  // Normalize overrides to lowercase keys and values for consistent lookup
        posOverrides = (posOverrides ?? {}).map(
              (k, v) => MapEntry(k.toLowerCase(), v.map((s) => s.toUpperCase()).toSet()),
        ),
        treatEntryAsNounIfExists = treatEntryAsNounIfExists ?? true;

  void clearCache() => _cache.clear();

  /// Checks if [word] is an Adjective.
  /// Note: English adjectives are hard to detect via suffix heuristics alone.
  /// This relies heavily on the Dictionary or Overrides.
  bool isAdjective(String word) => _hasPos(word, POS.ADJ);

  bool isAdverb(String word) {
    final lower = word.toLowerCase();
    if (_hasPos(lower, POS.ADV)) return true;

    // Heuristics: -ly words are often adverbs.
    if (lower.endsWith('ly') && !lower.endsWith('ally') && !lower.endsWith('lyre')) {
      // Ensure it's not a known noun (e.g. 'family', 'fly')
      if (commonNouns.contains(lower)) return false;
      return true;
    }
    if (commonAdverbs.contains(lower)) return true;
    return false;
  }

  bool isConjunction(String word) => conjunctions.contains(word.toLowerCase());

  bool isDeterminer(String word) => determiners.contains(word.toLowerCase());

  bool isPreposition(String word) => prepositions.contains(word.toLowerCase());

  bool isPronoun(String word) => pronouns.contains(word.toLowerCase());

  /// Checks if [word] is a Noun (singular or plural).
  bool isNoun(String word) {
    // Check explicit Noun first (singular)
    if (_hasPos(word, POS.NOUN)) return true;

    // Fallback to checking plural forms
    return isNounPlural(word);
  }

  bool isNounPlural(String word) {
    final lower = word.toLowerCase();
    if (!lower.endsWith('s')) return false;

    // Exceptions (e.g. 'status', 'class' end in s but are singular)
    if (singularNounExceptions.contains(lower)) return false;

    // Irregulars (e.g. 'children')
    if (irregularPlurals.containsKey(lower)) return true;

    // Morphology checks:
    // 1. -ies (entities -> entity)
    if (lower.endsWith('ies')) {
      final root = '${lower.substring(0, lower.length - 3)}y';
      if (_hasPos(root, POS.NOUN)) return true;
    }

    // 2. -es (boxes -> box)
    if (lower.endsWith('es')) {
      final root = lower.substring(0, lower.length - 2);
      if (_hasPos(root, POS.NOUN)) return true;
    }

    // 3. -s (users -> user)
    final root = lower.substring(0, lower.length - 1);
    if (_hasPos(root, POS.NOUN)) return true;

    return false;
  }

  bool isNounSingular(String word) => isNoun(word) && !isNounPlural(word);

  bool isVerb(String word) => _hasPos(word, POS.VERB);

  /// Heuristic to determine if a word is a verb gerund (ending in "-ing").
  bool isVerbGerund(String word) {
    final lower = word.toLowerCase();
    if (!lower.endsWith('ing') || lower.length < 4) return false;

    // If it's explicitly a verb in the dictionary (e.g. "bring"), it's not a gerund of something else.
    if (isVerb(word)) return true;

    // Check roots:
    final stem = lower.substring(0, lower.length - 3); // "load" from "loading"

    // Case: Doubling (getting -> get)
    if (stem.length > 1 && stem.endsWith(stem[stem.length - 1])) {
      if (isVerb(stem.substring(0, stem.length - 1))) return true;
    }

    // Case: Standard or dropped-e (updating -> update, loading -> load)
    return isVerb(stem) || isVerb('${stem}e');
  }

  /// Heuristic to determine if a word is a past-tense verb.
  bool isVerbPast(String word) {
    final lower = word.toLowerCase();

    // Known irregulars (e.g. "went", "saw")
    if (irregularPastVerbs.containsKey(lower)) return true;

    // If it's explicitly an adjective (e.g. "red"), prioritize that over verb logic unless ambiguous.
    if (isAdjective(word) && !isVerb(word)) return false;

    if (lower.endsWith('ed')) {
      final stem = lower.substring(0, lower.length - 2);
      if (stem.isEmpty) return false;

      // Case: Doubling (stopped -> stop)
      if (stem.length > 1 && stem.endsWith(stem[stem.length - 1])) {
        if (isVerb(stem.substring(0, stem.length - 1))) return true;
      }
      // Case: Standard or dropped-e (created -> create, loaded -> load)
      return isVerb(stem) || isVerb('${stem}e');
    }

    return isVerb(word);
  }

  /// Internal method to check the Part of Speech.
  bool _hasPos(String word, POS pos) {
    final lower = word.toLowerCase();
    final key = CacheKey(pos, lower);

    final cached = _cache[key];
    if (cached != null && !_isExpired(cached)) return cached.value;

    // 1. Overrides (Highest Priority)
    final ov = posOverrides[lower];
    if (ov != null) {
      // We store enum names as uppercase strings in the map (e.g. "NOUN")
      final result = ov.contains(pos.name.toUpperCase());
      _cache[key] = CacheValue(result);
      return result;
    }

    // 2. Common Constants (Fast Path)
    if (pos == POS.NOUN && commonNouns.contains(lower)) {
      _cache[key] = CacheValue(true);
      return true;
    }
    if (pos == POS.VERB && commonVerbs.contains(lower)) {
      _cache[key] = CacheValue(true);
      return true;
    }
    if (pos == POS.ADV && commonAdverbs.contains(lower)) {
      _cache[key] = CacheValue(true);
      return true;
    }

    // 3. Dictionary Lookup (Slowest)
    final result = _lookupDictionary(lower, pos);
    _cache[key] = CacheValue(result);
    return result;
  }

  bool _lookupDictionary(String lower, POS pos) {
    if (_dictionary == null) return false;
    try {
      final entry = _dictionary.getEntry(lower);

      // Strict Check: Does the entry have the requested POS?
      if (entry.meanings.any((m) => m.pos == pos)) return true;

      // Weak Signal for Nouns: If the word exists in dictionary at all,
      // and we are asking "Is it a Noun?", treat it as true.
      // This helps with obscure words that might technically be nouns.
      if (treatEntryAsNounIfExists && pos == POS.NOUN) return true;

      return false;
    } catch (_) {
      return false;
    }
  }

  bool _isExpired(CacheValue<dynamic> value) {
    return cacheTtl != null && DateTime.now().difference(value.timestamp) > cacheTtl!;
  }
}
