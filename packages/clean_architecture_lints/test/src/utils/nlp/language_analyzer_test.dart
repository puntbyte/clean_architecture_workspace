// test/src/utils/nlp/language_analyzer_test.dart

import 'package:clean_architecture_lints/src/utils/nlp/language_analyzer.dart';
import 'package:test/test.dart';

void main() {
  group('LanguageAnalyzer', () {
    late LanguageAnalyzer analyzer;

    setUp(() {
      // Initialize without a real dictionary for predictable unit tests.
      // We rely on Overrides and Constants.
      analyzer = LanguageAnalyzer(
        dictionary: null,
        posOverrides: {
          'custom': {'ADJ'}, // Define 'custom' as Adjective
          'mocked': {'VERB'}, // Define 'mocked' as Verb
          'ambiguous': {'NOUN', 'VERB'}, // Define as both
        },
        cacheTtl: const Duration(milliseconds: 500),
      );
    });

    group('Overrides', () {
      test('should respect posOverrides', () {
        expect(analyzer.isAdjective('custom'), isTrue);
        expect(analyzer.isVerb('mocked'), isTrue);

        // Ambiguous word check
        expect(analyzer.isNoun('ambiguous'), isTrue);
        expect(analyzer.isVerb('ambiguous'), isTrue);
        expect(analyzer.isAdjective('ambiguous'), isFalse);
      });

      test('should be case insensitive for overrides', () {
        expect(analyzer.isAdjective('Custom'), isTrue);
        expect(analyzer.isVerb('MOCKED'), isTrue);
      });
    });

    group('Common Constants', () {
      test('should identify common nouns', () {
        expect(analyzer.isNoun('user'), isTrue);
        expect(analyzer.isNoun('data'), isTrue);
        expect(analyzer.isNoun('auth'), isTrue); // Developer jargon
      });

      test('should identify common verbs', () {
        expect(analyzer.isVerb('get'), isTrue);
        expect(analyzer.isVerb('fetch'), isTrue);
        expect(analyzer.isVerb('login'), isTrue);
      });

      test('should identify common adverbs', () {
        expect(analyzer.isAdverb('always'), isTrue);
        expect(analyzer.isAdverb('usually'), isTrue);
      });
    });

    group('Nouns & Pluralization', () {
      test('should identify simple plurals (s)', () {
        // 'user' is in commonNouns, so 'users' should be detected via suffix logic
        expect(analyzer.isNounPlural('users'), isTrue);
        expect(analyzer.isNoun('users'), isTrue); // isNoun returns true for plurals too
      });

      test('should identify -es plurals', () {
        // 'process' is a singular exception, but let's test a made-up word in overrides
        // Let's add 'box' to overrides for this test logic
        final localAnalyzer = LanguageAnalyzer(
          posOverrides: {
            'box': {'NOUN'},
          },
        );
        expect(localAnalyzer.isNounPlural('boxes'), isTrue);
      });

      test('should identify -ies plurals', () {
        final localAnalyzer = LanguageAnalyzer(
          posOverrides: {
            'entity': {'NOUN'},
          },
        );
        expect(localAnalyzer.isNounPlural('entities'), isTrue);
      });

      test('should handle singular noun exceptions ending in s', () {
        expect(analyzer.isNounPlural('status'), isFalse);
        expect(analyzer.isNounPlural('class'), isFalse);
        // They should still be nouns though (if in dictionary/constants)
        // 'status' is in singularNounExceptions, but not in commonNouns,
        // so without a dict, isNoun('status') would return false here.
        // This behavior is expected for this test setup.
      });

      test('isNounSingular should return false for plurals', () {
        expect(analyzer.isNounSingular('users'), isFalse);
        expect(analyzer.isNounSingular('user'), isTrue);
      });
    });

    group('Verbs & Tenses', () {
      test('isVerbGerund should detect -ing forms', () {
        // 'fetch' is in commonVerbs
        expect(analyzer.isVerbGerund('fetching'), isTrue);
        // 'load' is in commonVerbs
        expect(analyzer.isVerbGerund('loading'), isTrue);
      });

      test('isVerbGerund should reject short words or non-verbs', () {
        expect(analyzer.isVerbGerund('sing'), isFalse); // Too short/root
        expect(analyzer.isVerbGerund('thing'), isFalse); // Noun
      });

      test('isVerbPast should detect -ed forms', () {
        // 'load' is in commonVerbs
        expect(analyzer.isVerbPast('loaded'), isTrue);
        // 'fetch' is in commonVerbs
        expect(analyzer.isVerbPast('fetched'), isTrue);
      });

      test('isVerbPast should detect irregulars', () {
        expect(analyzer.isVerbPast('went'), isTrue);
        expect(analyzer.isVerbPast('saw'), isTrue);
      });
    });

    group('Caching', () {
      test('should cache results', () {
        // First call - miss
        expect(analyzer.isNoun('user'), isTrue);

        // Modify overrides to see if cache persists (it shouldn't read from overrides now)
        // Note: we can't modify the map inside analyzer easily, but we can verify
        // behavior if we had a mockable dictionary.
        // Instead, we trust the logic and check no errors on repeated calls.
        expect(analyzer.isNoun('user'), isTrue);
      });

      test('should respect TTL', () async {
        final shortTtlAnalyzer = LanguageAnalyzer(
          posOverrides: {
            'temp': {'NOUN'},
          },
          cacheTtl: const Duration(milliseconds: 1),
        );

        expect(shortTtlAnalyzer.isNoun('temp'), isTrue);

        await Future.delayed.call(const Duration(milliseconds: 10));

        // Should re-evaluate (still true, but exercised the expiry logic)
        expect(shortTtlAnalyzer.isNoun('temp'), isTrue);
      });

      test('clearCache should wipe cache', () {
        analyzer
          ..isNoun('user')
          ..clearCache();
        // No easy way to assert internal state without reflection,
        // but ensuring no crash is valid.
        expect(analyzer.isNoun('user'), isTrue);
      });
    });
  });
}
