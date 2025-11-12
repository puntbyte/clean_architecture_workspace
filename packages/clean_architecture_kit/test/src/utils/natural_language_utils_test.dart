// test/src/utils/natural_language_utils_test.dart

import 'package:clean_architecture_kit/src/utils/natural_language_utils.dart';
import 'package:test/test.dart';

void main() {
  group('NaturalLanguageUtils', () {
    late NaturalLanguageUtils nlpUtils;

    setUpAll(() {
      final posOverrides = <String, Set<String>>{
        'get': {'VERB'},
        'save': {'VERB'},
        'delete': {'VERB'},
        'update': {'VERB'},
        'send': {'VERB'},
        'request': {'VERB'},
        'user': {'NOUN'},
        'profile': {'NOUN'},
        'email': {'NOUN'},
        'data': {'NOUN'},
        'successful': {'ADJ'},
        'empty': {'ADJ'},
        'invalid': {'ADJ'},
        'initial': {'ADJ'},
        'id': {'NOUN'},
      };
      nlpUtils = NaturalLanguageUtils(dictionary: null, posOverrides: posOverrides);
    });

    group('splitPascalCase', () {
      test('should split a simple two-word name', () {
        expect(nlpUtils.splitPascalCase('GetUser'), ['Get', 'User']);
      });

      test('should split a multi-word name', () {
        expect(nlpUtils.splitPascalCase('SendPasswordResetEmail'), [
          'Send',
          'Password',
          'Reset',
          'Email',
        ]);
      });

      test('should handle single-word names', () {
        expect(nlpUtils.splitPascalCase('User'), ['User']);
      });

      test('should handle acronyms correctly', () {
        expect(nlpUtils.splitPascalCase('HandleDTO'), ['Handle', 'DTO']);
      });

      test('should return an empty list for an empty string', () {
        expect(nlpUtils.splitPascalCase(''), isEmpty);
      });
    });

    group('Part of Speech checks (using overrides)', () {
      test('isVerb should identify common verbs', () {
        expect(nlpUtils.isVerb('Get'), isTrue, reason: 'Get is a verb');
        expect(nlpUtils.isVerb('Save'), isTrue);
        expect(nlpUtils.isVerb('Delete'), isTrue);
        expect(nlpUtils.isVerb('Update'), isTrue);
        expect(nlpUtils.isVerb('Send'), isTrue);
      });

      test('isNoun should identify common nouns', () {
        expect(nlpUtils.isNoun('User'), isTrue);
        expect(nlpUtils.isNoun('Profile'), isTrue);
        expect(nlpUtils.isNoun('Email'), isTrue);
        expect(nlpUtils.isNoun('Data'), isTrue);
        // 'Bloc' is not in the overrides and is intentionally not in the small fallback set,
        // so we expect false for technical terms.
        expect(nlpUtils.isNoun('Bloc'), isFalse);
      });

      test('isAdjective should identify common adjectives', () {
        expect(nlpUtils.isAdjective('Successful'), isTrue);
        expect(nlpUtils.isAdjective('Empty'), isTrue);
        expect(nlpUtils.isAdjective('Invalid'), isTrue);
        expect(nlpUtils.isAdjective('Initial'), isTrue);
      });

      test('unknown words should return false', () {
        // Not present in overrides and dictionary disabled -> false.
        expect(nlpUtils.isVerb('Fhqwhgads'), isFalse);
        expect(nlpUtils.isNoun('Xyzzy'), isFalse);
        expect(nlpUtils.isAdjective('Plugh'), isFalse);
      });
    });

    group('Heuristic checks for verb forms', () {
      test('isVerbGerund should identify -ing forms of known verbs', () {
        expect(nlpUtils.isVerbGerund('Loading'), isTrue);
        expect(nlpUtils.isVerbGerund('Updating'), isTrue); // update -> updating
        expect(nlpUtils.isVerbGerund('Setting'), isTrue); // set -> setting (fallback commonVerbs)
        expect(nlpUtils.isVerbGerund('Getting'), isTrue);
      });

      test('isVerbGerund should reject nouns ending in -ing', () {
        // Not declared as verbs in overrides; expect false to reflect noun use.
        expect(nlpUtils.isVerbGerund('Morning'), isFalse);
        expect(nlpUtils.isVerbGerund('Building'), isFalse);
      });

      test('isVerbPast should identify regular past tense verbs', () {
        expect(nlpUtils.isVerbPast('Requested'), isTrue);
        expect(nlpUtils.isVerbPast('Updated'), isTrue);
        expect(nlpUtils.isVerbPast('Deleted'), isTrue);
      });

      test('isVerbPast should identify common irregular past tense verbs', () {
        expect(nlpUtils.isVerbPast('Sent'), isTrue);
        expect(nlpUtils.isVerbPast('Found'), isTrue);
        expect(nlpUtils.isVerbPast('Built'), isTrue);
      });

      test('isVerbPast should reject adjectives ending in -ed', () {
        // 'Red' is an adjective, not past verb
        expect(nlpUtils.isVerbPast('Red'), isFalse);
        // 'Nested' could be ambiguous; our overrides do not mark as verb, so false.
        expect(nlpUtils.isVerbPast('Nested'), isFalse);
      });
    });

    group('Caching Behavior', () {
      test('cache grows after repeated checks', () {
        nlpUtils.clearCache();
        expect(nlpUtils.cacheSize, equals(0));
        // repeated calls to populate cache
        nlpUtils
          ..isVerb('Get')
          ..isVerb('Get')
          ..isNoun('User')
          ..isNoun('User');
        // Now the cache should have entries
        expect(nlpUtils.cacheSize, greaterThan(0));
      });
    });
  });
}
