import 'package:clean_architecture_kit/src/models/naming_config.dart';
import 'package:test/test.dart';

void main() {
  group('NamingRule', () {
    group('from factory', () {
      const defaultPattern = '{{name}}Default';

      // --- Test Case 1: Parsing from a simple String ---
      test('should create from a simple string pattern', () {
        const data = '{{name}}Pattern';
        final rule = NamingRule.from(data, defaultPattern);

        expect(rule.pattern, equals(data));
        expect(rule.antipatterns, isEmpty);
      });

      // --- Test Cases 2: Parsing from a Map ---
      test('should create from a map with pattern and anti_pattern', () {
        final data = {
          'pattern': '{{name}}',
          'anti_pattern': ['{{name}}Entity', '{{name}}UseCase'],
        };
        final rule = NamingRule.from(data, defaultPattern);

        expect(rule.pattern, equals('{{name}}'));
        expect(rule.antipatterns, hasLength(2));
        expect(rule.antipatterns, containsAll(['{{name}}Entity', '{{name}}UseCase']));
      });

      test('should create from a map with only a pattern', () {
        final data = {'pattern': '{{name}}Model'};
        final rule = NamingRule.from(data, defaultPattern);

        expect(rule.pattern, equals('{{name}}Model'));
        expect(rule.antipatterns, isEmpty);
      });

      test('should use default pattern when map is missing "pattern" key', () {
        final data = {
          'anti_pattern': ['{{name}}Suffix'],
        };
        final rule = NamingRule.from(data, defaultPattern);

        expect(rule.pattern, equals(defaultPattern));
        expect(rule.antipatterns, equals(['{{name}}Suffix']));
      });

      test('should create from an empty map using defaults', () {
        final data = <String, dynamic>{};
        final rule = NamingRule.from(data, defaultPattern);

        expect(rule.pattern, equals(defaultPattern));
        expect(rule.antipatterns, isEmpty);
      });

      // --- Test Cases 3: Fallback Behavior ---
      test('should use default pattern when data is null', () {
        const data = null;
        final rule = NamingRule.from(data, defaultPattern);

        expect(rule.pattern, equals(defaultPattern));
        expect(rule.antipatterns, isEmpty);
      });

      test('should use default pattern for invalid data types like int', () {
        const data = 123;
        final rule = NamingRule.from(data, defaultPattern);

        expect(rule.pattern, equals(defaultPattern));
        expect(rule.antipatterns, isEmpty);
      });

      test('should use default pattern for invalid data types like List', () {
        final data = ['not', 'a', 'map'];
        final rule = NamingRule.from(data, defaultPattern);

        expect(rule.pattern, equals(defaultPattern));
        expect(rule.antipatterns, isEmpty);
      });
    });
  });
}
