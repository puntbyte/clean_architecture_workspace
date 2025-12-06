import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:test/test.dart';

void main() {
  group('Definition', () {
    group('fromDynamic', () {
      test('should parse shorthand string', () {
        final def = Definition.fromDynamic('MyClass');
        expect(def.type, 'MyClass');
        expect(def.isWildcard, isFalse);
        expect(def.import, isNull);
      });

      test('should parse wildcard string', () {
        final def = Definition.fromDynamic('*');
        expect(def.isWildcard, isTrue);
        expect(def.type, isNull);
      });

      test('should parse detailed map with type and import', () {
        final map = {
          'type': 'MyClass',
          'import': 'package:pkg/file.dart',
        };
        final def = Definition.fromDynamic(map);

        expect(def.type, 'MyClass');
        expect(def.import, 'package:pkg/file.dart');
      });

      test('should parse identifiers (string and list)', () {
        // String shorthand
        final def1 = Definition.fromDynamic({'identifiers': 'sl'});
        expect(def1.identifiers, ['sl']);

        // List
        final def2 = Definition.fromDynamic({'identifiers': ['sl', 'locator']});
        expect(def2.identifiers, ['sl', 'locator']);
      });

      test('should parse references (definition and component)', () {
        // Definition Reference
        final defRef = Definition.fromDynamic({'definition': 'failure.base'});
        expect(defRef.ref, 'failure.base');
        expect(defRef.component, isNull);

        // Component Reference
        final compRef = Definition.fromDynamic({'component': 'domain.model'});
        expect(compRef.component, 'domain.model');
        expect(compRef.ref, isNull);
      });

      test('should parse recursive generic arguments', () {
        final map = {
          'type': 'Either',
          'argument': [
            {'type': 'Left'},
            // Nested recursion
            {
              'type': 'Right',
              'argument': 'String' // Shorthand inside argument
            }
          ]
        };

        final def = Definition.fromDynamic(map);

        expect(def.type, 'Either');
        expect(def.arguments, hasLength(2));

        expect(def.arguments[0].type, 'Left');

        expect(def.arguments[1].type, 'Right');
        expect(def.arguments[1].arguments.first.type, 'String');
      });

      test('should inherit import from parent context', () {
        final def = Definition.fromDynamic(
          {'type': 'Child'},
          currentImport: 'package:parent/lib.dart',
        );

        expect(def.type, 'Child');
        expect(def.import, 'package:parent/lib.dart');
      });

      test('should override inherited import if specified', () {
        final def = Definition.fromDynamic(
          {'type': 'Child', 'import': 'package:child/lib.dart'},
          currentImport: 'package:parent/lib.dart',
        );

        expect(def.import, 'package:child/lib.dart');
      });
    });

    group('parseRegistry', () {
      test('should parse nested registry map using HierarchyParser', () {
        final yaml = {
          'domain': {
            '.base': 'DomainEntity', // Added dot
            '.sub': {'type': 'SubEntity'} // Added dot
          }
        };

        final registry = Definition.parseRegistry(yaml);

        // Expect keys WITHOUT dots in the result map
        expect(registry.keys, containsAll(['domain.base', 'domain.sub']));
        expect(registry['domain.base']?.type, 'DomainEntity');
        expect(registry['domain.sub']?.type, 'SubEntity');
      });
    });
  });
}
