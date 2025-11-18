// test/src/utils/natural_language_utils_test.dart

import 'package:clean_architecture_lints/src/utils/natural_language_utils.dart';
import 'package:test/test.dart';

void main() {
  group('NaturalLanguageUtils', () {
    late NaturalLanguageUtils nlpUtils;

    setUpAll(() {
      final posOverrides = <String, Set<String>>{
        'get': {'VERB'}, 'save': {'VERB'}, 'update': {'VERB'}, 'request': {'VERB'}, 'apply': {'VERB'},
        'user': {'NOUN'}, 'profile': {'NOUN'}, 'email': {'NOUN'}, 'morning': {'NOUN'},
        'successful': {'ADJ'}, 'empty': {'ADJ'}, 'invalid': {'ADJ'},
        // Ambiguous words for testing precedence rules
        'building': {'NOUN'},
        'nested': {'ADJ'},
      };
      nlpUtils = NaturalLanguageUtils(posOverrides: posOverrides);
    });

    setUp(() {
      nlpUtils.clearCache();
    });

    group('Part of Speech checks', () {
      test('should return true for verbs defined in overrides', () {
        expect(nlpUtils.isVerb('Get'), isTrue);
        expect(nlpUtils.isVerb('Save'), isTrue);
      });

      test('should return true for nouns defined in overrides', () {
        expect(nlpUtils.isNoun('User'), isTrue);
        expect(nlpUtils.isNoun('Email'), isTrue);
      });

      test('should return true for adjectives defined in overrides', () {
        expect(nlpUtils.isAdjective('Successful'), isTrue);
        expect(nlpUtils.isAdjective('Invalid'), isTrue);
      });

      test('should return false for unknown words when dictionary is disabled', () {
        expect(nlpUtils.isVerb('NonExistentVerb'), isFalse);
        expect(nlpUtils.isNoun('NonExistentNoun'), isFalse);
      });
    });

    group('isVerbGerund', () {
      test('should return true for simple -ing form of a known verb', () {
        expect(nlpUtils.isVerbGerund('Updating'), isTrue); // update -> updating
      });

      test('should return true for -ing form with a dropped e', () {
        expect(nlpUtils.isVerbGerund('Saving'), isTrue); // save -> saving
      });

      test('should return false for a word that is primarily a noun ending in -ing', () {
        expect(nlpUtils.isVerbGerund('Building'), isFalse, reason: 'Building is defined as a noun.');
        expect(nlpUtils.isVerbGerund('Morning'), isFalse);
      });
    });

    group('isVerbPast', () {
      test('should return true for regular -ed verb', () {
        expect(nlpUtils.isVerbPast('Requested'), isTrue);
      });

      test('should return true for -ied verb from a "y" stem', () {
        expect(nlpUtils.isVerbPast('Applied'), isTrue); // apply -> applied
      });

      test('should return true for common irregular verbs', () {
        expect(nlpUtils.isVerbPast('Sent'), isTrue);
        expect(nlpUtils.isVerbPast('Built'), isTrue);
      });

      test('should return false for a word that is primarily an adjective ending in -ed', () {
        expect(nlpUtils.isVerbPast('Nested'), isFalse, reason: 'Nested is defined as an adjective.');
      });
    });

    group('Caching', () {
      test('should cache results to avoid re-computation', () {
        expect(nlpUtils.cacheSize, 0);

        // First call populates the cache
        final result1 = nlpUtils.isNoun('User');
        expect(result1, isTrue);
        expect(nlpUtils.cacheSize, 1);

        // Second call should hit the cache
        final result2 = nlpUtils.isNoun('User');
        expect(result2, isTrue);
        expect(nlpUtils.cacheSize, 1, reason: 'Cache size should not increase on a cache hit.');
      });
    });
  });
}
