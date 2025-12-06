import 'package:architecture_lints/src/config/parsing/hierarchy_parser.dart';
import 'package:test/test.dart';

/// Simple DTO to verify parser output
class TestItem {
  final String id;
  final dynamic value; // Can be Map or String

  TestItem(this.id, this.value);

  @override
  String toString() => '$id: $value';

  @override
  bool operator ==(Object other) => other is TestItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

void main() {
  group('HierarchyParser', () {

    // Helper factory that accepts Map OR String
    TestItem createItem(String id, dynamic value) {
      return TestItem(id, value);
    }

    // Helper validator
    bool isValidNode(dynamic value) {
      if (value is String) return true; // Shorthand is valid
      if (value is Map) return value.containsKey('valid'); // Maps need a flag
      return false;
    }

    Map<String, TestItem> runParser(
        Map<String, dynamic> yaml, {
          Set<String> scopeKeys = const {},
        }) {
      return HierarchyParser.parse<TestItem>(
        yaml: yaml,
        scopeKeys: scopeKeys,
        factory: createItem,
        shouldParseNode: isValidNode,
      );
    }

    test('should parse top-level flat keys', () {
      final yaml = {
        'flat_a': {'valid': true},
        'flat_b': 'ShorthandValue', // String value at root
      };

      final result = runParser(yaml);

      expect(result.keys, containsAll(['flat_a', 'flat_b']));
      expect(result['flat_b']?.value, 'ShorthandValue');
    });

    test('should parse top-level keys starting with dot (strip dot)', () {
      final yaml = {
        '.domain': {'valid': true},
      };

      final result = runParser(yaml);

      expect(result.keys, contains('domain'));
      expect(result.keys, isNot(contains('.domain')));
    });

    test('should parse nested hierarchies (requiring dots)', () {
      final yaml = {
        'domain': {
          'valid': true,
          '.entity': { // Starts with dot -> Child
            'valid': true,
            '.field': 'FieldShorthand' // Nested Shorthand
          },
          'ignored_child': {'valid': true} // No dot -> Property -> Ignored
        }
      };

      final result = runParser(yaml);

      // Should contain the dotted hierarchy
      expect(result.keys, containsAll([
        'domain',
        'domain.entity',
        'domain.entity.field',
      ]));

      // Should NOT contain the child without a dot
      expect(result.keys, isNot(contains('domain.ignored_child')));
    });

    test('should handle Module scoping correctly', () {
      final scopes = {'core', 'infra'};

      final yaml = {
        // 'core' is a scope key. It resets the path.
        'core': {
          '.network': {'valid': true},
          '.db': 'DbShorthand'
        },
        // 'feature' is NOT a scope key. It is treated as a component root.
        'feature': {
          'valid': true,
          '.auth': {'valid': true}
        }
      };

      final result = runParser(yaml, scopeKeys: scopes);

      expect(result.keys, containsAll([
        'core.network',
        'core.db',
        'feature',
        'feature.auth',
      ]));

      // 'core' itself is not a result (unless it matched valid logic, which scopes usually don't)
      expect(result.containsKey('core'), isFalse);
    });

    test('should support structural containers (nodes that are not items themselves)', () {
      // Logic: A node might fail `shouldParseNode` (e.g. missing 'valid: true'),
      // but we still traverse its children.
      final yaml = {
        '.domain': {
          // No 'valid: true' here, just a folder
          '.usecase': {
            'valid': true // This one is valid
          }
        }
      };

      final result = runParser(yaml);

      expect(result.containsKey('domain'), isFalse); // Container skipped
      expect(result.containsKey('domain.usecase'), isTrue); // Child found
    });

    test('should ignore non-map properties inside nested nodes', () {
      final yaml = {
        '.domain': {
          'valid': true,
          'path': 'some/path', // String property
          'list': ['a', 'b'],  // List property
          '.child': {'valid': true}
        }
      };

      final result = runParser(yaml);

      expect(result.keys, containsAll(['domain', 'domain.child']));
      expect(result.length, 2);
    });
  });
}