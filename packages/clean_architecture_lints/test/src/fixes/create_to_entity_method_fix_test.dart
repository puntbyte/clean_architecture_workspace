// test/src/fixes/create_to_entity_method_fix_test.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/fixes/create_to_entity_method_fix.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('CreateToEntityMethodFix Logic', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('to_entity_fix_test_');
      projectPath = p.normalize(tempDir.path);
      final testProjectPath = p.join(projectPath, 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      final pubspecPath = p.join(testProjectPath, 'pubspec.yaml');
      resourceProvider.getFile(pubspecPath)
        ..parent.create()
        ..writeAsStringSync('name: test_project');

      final packageConfigPath = p.join(testProjectPath, '.dart_tool', 'package_config.json');
      resourceProvider.getFile(packageConfigPath)
        ..parent.create()
        ..writeAsStringSync(
          '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
          '"packageUri": "lib/"}]}',
        );

      contextCollection = AnalysisContextCollection(
        includedPaths: [testProjectPath],
        resourceProvider: resourceProvider,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should generate valid toEntity method with matching fields mapping', () async {
      final testProjectPath = p.join(projectPath, 'test_project');

      // 1. Define the Entity in the virtual FS.
      // FIX: Use p.join for all path segments and normalize.
      final entityPath = p.normalize(p.join(testProjectPath, 'lib', 'entity.dart'));
      resourceProvider.getFile(entityPath)
        ..parent.create()
        ..writeAsStringSync('''
        class UserEntity {
          final String id;
          final String name;
          UserEntity(this.id, {required this.name});
        }
      ''');

      // 2. Define the Model in the virtual FS.
      final modelPath = p.normalize(p.join(testProjectPath, 'lib', 'model.dart'));
      resourceProvider.getFile(modelPath).writeAsStringSync('''
        import 'entity.dart';
        class UserModel {
          final String id;
          final String name;
          final String other;
        }
      ''');

      // 3. Resolve the files to get real Elements and Nodes.
      final entityResult =
          await contextCollection.contextFor(entityPath).currentSession.getResolvedUnit(entityPath)
              as ResolvedUnitResult;

      final modelResult =
          await contextCollection.contextFor(modelPath).currentSession.getResolvedUnit(modelPath)
              as ResolvedUnitResult;

      // 4. Extract the specific inputs for the builder.
      final entityElement =
          entityResult.unit.declarations.first.declaredFragment!.element as InterfaceElement;
      final modelNode = modelResult.unit.declarations.first as ClassDeclaration;

      // 5. Execute the static builder logic.
      final methodSpec = CreateToEntityMethodFix.buildToEntityMethod(
        modelNode: modelNode,
        entityElement: entityElement,
        entityName: 'UserEntity',
      );

      // 6. Verify the output using CodeBuilder emitter.
      final emitter = cb.DartEmitter(useNullSafetySyntax: true);
      final source = methodSpec.accept(emitter).toString();

      // Expect the method signature
      expect(source, contains('@override'));
      expect(source, contains('UserEntity toEntity()'));

      // Expect correct mapping: id (positional) -> id, name (named) -> name
      // Positional arg:
      expect(source, contains('UserEntity(id,'));
      // Named arg:
      expect(source, contains('name: name'));
    });

    test('should generate UnimplementedError for missing fields', () async {
      final testProjectPath = p.join(projectPath, 'test_project');

      // Entity requires 'email', but Model doesn't have it.
      final entityPath = p.normalize(p.join(testProjectPath, 'lib', 'entity.dart'));
      resourceProvider.getFile(entityPath)
        ..parent.create()
        ..writeAsStringSync('''
        class UserEntity {
          final String email;
          UserEntity({required this.email});
        }
      ''');

      final modelPath = p.normalize(p.join(testProjectPath, 'lib', 'model.dart'));
      resourceProvider.getFile(modelPath).writeAsStringSync('''
        class UserModel {
          final String name; 
        }
      ''');

      final entityResult =
          await contextCollection.contextFor(entityPath).currentSession.getResolvedUnit(entityPath)
              as ResolvedUnitResult;
      final modelResult =
          await contextCollection.contextFor(modelPath).currentSession.getResolvedUnit(modelPath)
              as ResolvedUnitResult;

      final entityElement =
          entityResult.unit.declarations.first.declaredFragment!.element as InterfaceElement;
      final modelNode = modelResult.unit.declarations.first as ClassDeclaration;

      final methodSpec = CreateToEntityMethodFix.buildToEntityMethod(
        modelNode: modelNode,
        entityElement: entityElement,
        entityName: 'UserEntity',
      );

      final source = methodSpec.accept(cb.DartEmitter(useNullSafetySyntax: true)).toString();

      // Expect the specific TODO message for the missing field
      expect(source, contains("throw UnimplementedError('TODO: Map field \"email\"')"));
    });
  });
}
