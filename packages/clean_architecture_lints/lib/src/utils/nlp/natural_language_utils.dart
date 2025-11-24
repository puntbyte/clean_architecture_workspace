// lib/src/utils/nlp/natural_language_utils.dart

import 'package:dictionaryx/dictentry.dart';
import 'package:dictionaryx/dictionary_msa.dart';

class NaturalLanguageUtils {
  final DictionaryMSA? _dictionary;
  final Map<(POS, String), bool> _cache = {};
  final Map<String, Set<String>> _posOverrides;

  // Words that end in 's' but are typically Singular Nouns in coding contexts
  static const _singularExceptions = {
    'status', 'access', 'process', 'class', 'address', 'canvas', 'focus',
    'loss', 'glass', 'pass', 'progress', 'analysis', 'diagnosis'
  };

  // ... (Keep existing _commonNouns, _commonVerbs, etc.) ...
  static const _commonNouns = {
    'email', 'profile', 'data', 'user', 'state', 'event', 'auth', 'dto',
    'request', 'response', 'id', 'text', 'date', 'image', 'list', 'map',
    'type', 'info', 'detail', 'item', 'violation', 'port'
  };
  static const _commonVerbs = {
    'get', 'set', 'fetch', 'send', 'save', 'delete', 'update', 'load',
    'login', 'logout', 'create', 'read', 'write', 'remove', 'add'
  };
  static const _commonIrregularPastVerbs = {
    'went', 'saw', 'did', 'took', 'said', 'came', 'gave', 'ran', 'ate', 'wrote',
    'was', 'were', 'had', 'knew', 'put', 'thought', 'became', 'showed', 'sent',
    'found', 'built', 'began', 'left',
  };

  NaturalLanguageUtils({DictionaryMSA? dictionary, Map<String, Set<String>>? posOverrides})
      : _dictionary = dictionary,
        _posOverrides = posOverrides ?? {};

  void clearCache() => _cache.clear();

  bool isVerb(String word) => _hasPos(word, POS.VERB);
  bool isAdjective(String word) => _hasPos(word, POS.ADJ);

  /// Checks if a word is a Noun (Singular OR Plural).
  bool isNoun(String word) {
    if (_hasPos(word, POS.NOUN)) return true;
    // If not found directly, check if it's a plural form of a known noun.
    return isNounPlural(word);
  }

  /// Checks if a word is likely a Plural Noun.
  bool isNounPlural(String word) {
    final lower = word.toLowerCase();

    // 1. Basic prerequisites
    if (!lower.endsWith('s')) return false;
    if (_singularExceptions.contains(lower)) return false;

    // 2. Check roots
    // 'ies' -> 'y' (Entities -> Entity)
    if (lower.endsWith('ies')) {
      final root = lower.substring(0, lower.length - 3) + 'y';
      if (_hasPos(root, POS.NOUN)) return true;
    }

    // 'es' -> '' (Boxes -> Box)
    if (lower.endsWith('es')) {
      final root = lower.substring(0, lower.length - 2);
      if (_hasPos(root, POS.NOUN)) return true;
    }

    // 's' -> '' (Users -> User)
    final root = lower.substring(0, lower.length - 1);
    if (_hasPos(root, POS.NOUN)) return true;

    return false;
  }

  /// Checks if a word is a Singular Noun.
  bool isNounSingular(String word) {
    // It must be a noun, and it must NOT be plural.
    // Exception: Words that are same in singular/plural (e.g. "Data") are treated as Singular here.
    return isNoun(word) && !isNounPlural(word);
  }

  bool _hasPos(String word, POS pos) {
    final lowerWord = word.toLowerCase();
    final cacheKey = (pos, lowerWord);
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final override = _posOverrides[lowerWord];
    if (override != null) {
      return _cache[cacheKey] = override.contains(pos.name);
    }

    if (pos == POS.NOUN && _commonNouns.contains(lowerWord)) return _cache[cacheKey] = true;
    if (pos == POS.VERB && _commonVerbs.contains(lowerWord)) return _cache[cacheKey] = true;

    if (_dictionary != null) {
      try {
        final entry = _dictionary.getEntry(lowerWord);
        final result = entry.meanings.any((m) => m.pos == pos);
        return _cache[cacheKey] = result;
      } catch (_) {}
    }

    return _cache[cacheKey] = false;
  }

  bool isVerbGerund(String word) {
    final lowerWord = word.toLowerCase();
    if (!lowerWord.endsWith('ing') || lowerWord.length < 4) return false;
    if (isNoun(word) && !isVerb(word)) return false;
    if (isVerb(word)) return true;

    final stem = lowerWord.substring(0, lowerWord.length - 3);
    if (stem.length > 1 && stem.endsWith(stem[stem.length - 1])) {
      if (isVerb(stem.substring(0, stem.length - 1))) return true;
    }
    return isVerb(stem) || isVerb('${stem}e');
  }

  bool isVerbPast(String word) {
    if (isAdjective(word) && !isVerb(word)) return false;
    final lowerWord = word.toLowerCase();
    if (_commonIrregularPastVerbs.contains(lowerWord)) return true;

    if (lowerWord.endsWith('ed')) {
      final stem = lowerWord.substring(0, lowerWord.length - 2);
      if (stem.isEmpty) return false;
      if (stem.length > 1 && stem.endsWith(stem[stem.length - 1])) {
        if (isVerb(stem.substring(0, stem.length - 1))) return true;
      }
      return isVerb(stem) || isVerb('${stem}e');
    }
    return isVerb(word);
  }
}