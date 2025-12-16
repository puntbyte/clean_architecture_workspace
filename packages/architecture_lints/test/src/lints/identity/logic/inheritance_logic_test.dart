import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:architecture_lints/src/schema/policies/inheritance_policy.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// 1. Mock Dependencies
class MockFileResolver extends Mock implements FileResolver {}

// 2. Concrete class to test the Mixin
class LogicTester with InheritanceLogic {}

void main() {
  group('InheritanceLogic', () {
    late Directory tempDir;
    late MockFileResolver mockResolver;
    late LogicTester tester;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('inheritance_logic_test_');
      mockResolver = MockFileResolver();
      tester = LogicTester();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    /// Helper: Resolves Dart code and returns the target ClassDeclaration.
    Future<ClassDeclaration> resolveClass(
      String content, {
      String fileName = 'test.dart',
      String? targetClassName,
    }) async {
      final file = File(p.join(tempDir.path, fileName))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);

      final result = await resolveFile(path: p.normalize(file.absolute.path));
      if (result is! ResolvedUnitResult) {
        throw StateError('Failed to resolve $fileName');
      }

      final classes = result.unit.declarations.whereType<ClassDeclaration>();

      if (classes.isEmpty) throw StateError('No classes found in test content');

      if (targetClassName != null) {
        return classes.firstWhere(
          (c) => c.name.lexeme == targetClassName,
          orElse: () => throw StateError('Class $targetClassName not found'),
        );
      }
      // Default to the last class (usually the subject class in our test snippets)
      return classes.last;
    }

    group('findComponentIdByInheritance', () {
      // Renamed: Removed quotes around 'extends' for easier CLI running
      test('should identify component based on extends matching a Rule', () async {
        const config = ArchitectureConfig(
          components: [],
          inheritances: [
            InheritancePolicy(
              onIds: ['entity'],
              required: [
                TypeDefinition(types: ['BaseEntity']),
              ],
              allowed: [],
              forbidden: [],
            ),
          ],
        );

        final node = await resolveClass('''
          class BaseEntity {}
          class UserEntity extends BaseEntity {}
        ''');

        final result = tester.findComponentIdByInheritance(node, config, mockResolver);

        expect(result, 'entity');
      });

      // Renamed: Removed quotes around 'implements'
      test('should identify component based on implements matching a Rule', () async {
        const config = ArchitectureConfig(
          components: [],
          inheritances: [
            InheritancePolicy(
              onIds: ['repository'],
              required: [
                TypeDefinition(types: ['RepoInterface']),
              ],
              allowed: [],
              forbidden: [],
            ),
          ],
        );

        final node = await resolveClass('''
          abstract class RepoInterface {}
          class AuthRepo implements RepoInterface {}
        ''');

        final result = tester.findComponentIdByInheritance(node, config, mockResolver);

        expect(result, 'repository');
      });

      test('should return null if no inheritance rule matches', () async {
        const config = ArchitectureConfig(inheritances: [], components: []);

        final node = await resolveClass('class UserEntity {}');

        final result = tester.findComponentIdByInheritance(node, config, mockResolver);

        expect(result, isNull);
      });
    });

    group('matchesDefinition', () {
      test('should match by Type Name', () async {
        const def = TypeDefinition(types: ['Base']);
        final node = await resolveClass('''
          class Base {}
          class Child extends Base {}
        ''');

        final superType = node.declaredFragment!.element.supertype!;

        final result = tester.matchesDefinition(superType, def, mockResolver, {});
        expect(result, isTrue);
      });

      test('should match by Import URI', () async {
        final libPath = p.join(tempDir.path, 'lib.dart');
        File(libPath).writeAsStringSync('class Remote {}');
        final libUri = p.toUri(libPath).toString();

        final def = TypeDefinition(types: const ['Remote'], imports: [libUri]);

        final node = await resolveClass('''
          import 'lib.dart';
          class Impl extends Remote {}
        ''');

        final superType = node.declaredFragment!.element.supertype!;

        final result = tester.matchesDefinition(superType, def, mockResolver, {});
        expect(result, isTrue);
      });

      test('should fail if Import URI does not match', () async {
        const def = TypeDefinition(
          types: ['Remote'],
          imports: ['package:wrong/lib.dart'],
        );

        final node = await resolveClass('''
          class Remote {} 
          class Impl extends Remote {}
        ''');

        final superType = node.declaredFragment!.element.supertype!;

        final result = tester.matchesDefinition(superType, def, mockResolver, {});
        expect(result, isFalse);
      });

      test('should match by Component Reference (Location)', () async {
        const def = TypeDefinition(component: 'domain.entity');

        final superPath = p.join(tempDir.path, 'entity_base.dart');
        File(superPath).writeAsStringSync('class BaseEntity {}');

        when(() => mockResolver.resolve(any())).thenAnswer((inv) {
          final pathArg = inv.positionalArguments.first as String;
          if (p.normalize(pathArg) == p.normalize(superPath)) {
            return ComponentContext(
              filePath: pathArg,
              definition: const ComponentDefinition(id: 'domain.entity', paths: []),
            );
          }
          return null;
        });

        final node = await resolveClass('''
          import 'entity_base.dart';
          class User extends BaseEntity {}
        ''', fileName: 'user.dart');

        final superType = node.declaredFragment!.element.supertype!;

        final result = tester.matchesDefinition(superType, def, mockResolver, {});
        expect(result, isTrue);
      });

      test('should match recursively via Reference (ref)', () async {
        final registry = {
          'core.base': const TypeDefinition(types: ['Base']),
        };
        const def = TypeDefinition(ref: 'core.base');

        final node = await resolveClass('''
          class Base {}
          class Child extends Base {}
        ''');

        final superType = node.declaredFragment!.element.supertype!;

        final result = tester.matchesDefinition(superType, def, mockResolver, registry);
        expect(result, isTrue);
      });

      test('should match Wildcard (*)', () async {
        const def = TypeDefinition(isWildcard: true);
        final node = await resolveClass('class A extends Object {}');
        final superType = node.declaredFragment!.element.supertype!;

        final result = tester.matchesDefinition(superType, def, mockResolver, {});
        expect(result, isTrue);
      });
    });

    group('getImmediateSupertypes', () {
      test('should include Extends, Implements, and Mixins', () async {
        final node = await resolveClass('''
          class Base {}
          mixin M {}
          class I {}
          
          class Child extends Base with M implements I {}
        ''', targetClassName: 'Child');

        final element = node.declaredFragment!.element;
        final types = tester.getImmediateSupertypes(element);

        final names = types.map((t) => t.element.name).toList();
        expect(names, containsAll(['Base', 'M', 'I', 'Object']));
      });
    });
  });
}
