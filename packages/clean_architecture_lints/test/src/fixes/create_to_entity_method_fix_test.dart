// test/src/fixes/create_to_entity_method_fix_test.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:clean_architecture_lints/src/fixes/create_to_entity_method_fix.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('CreateToEntityMethodFix Logic', () {
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('to_entity_fix_test_');
      testProjectPath = p.canonicalize(p.join(tempDir.path, 'test_project'));

      Directory(testProjectPath).createSync(recursive: true);

      final pubspecPath = p.join(testProjectPath, 'pubspec.yaml');
      File(pubspecPath).writeAsStringSync('name: test_project');

      final packageConfigPath = p.join(testProjectPath, '.dart_tool', 'package_config.json');
      File(packageConfigPath)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
        );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore Windows file lock errors
      }
    });

    test('generates valid toEntity method with matching fields mapping', () async {
      final entityPath = p.join(testProjectPath, 'lib', 'entity.dart');
      File(entityPath)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('''
        class UserEntity {
          final String id;
          final String name;
          UserEntity(this.id, {required this.name});
        }
      ''');

      final modelPath = p.join(testProjectPath, 'lib', 'model.dart');
      File(modelPath).writeAsStringSync('''
        import 'entity.dart';
        class UserModel {
          final String id;
          final String name;
          final String other;
        }
      ''');

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final entityResult = await contextCollection
          .contextFor(entityPath)
          .currentSession
          .getResolvedUnit(entityPath) as ResolvedUnitResult;

      final modelResult = await contextCollection
          .contextFor(modelPath)
          .currentSession
          .getResolvedUnit(modelPath) as ResolvedUnitResult;

      // Extract Elements
      final entityElement = entityResult.unit.declarations.first.declaredFragment!.element as InterfaceElement;
      final modelNode = modelResult.unit.declarations.first as ClassDeclaration;

      // Run Builder
      final methodSpec = CreateToEntityMethodFix.buildToEntityMethod(
        modelNode: modelNode,
        entityElement: entityElement,
        entityName: 'UserEntity',
      );

      final source = methodSpec.accept(cb.DartEmitter(useNullSafetySyntax: true)).toString();

      expect(source, contains('@override'));
      expect(source, contains('UserEntity toEntity()'));
      expect(source, contains('UserEntity(id,'));
      expect(source, contains('name: name'));
    });

    test('generates UnimplementedError for missing fields', () async {
      final entityPath = p.join(testProjectPath, 'lib', 'entity.dart');
      File(entityPath)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('''
        class UserEntity {
          final String email;
          UserEntity({required this.email});
        }
      ''');

      final modelPath = p.join(testProjectPath, 'lib', 'model.dart');
      File(modelPath).writeAsStringSync('''
        class UserModel {
          final String name; 
        }
      ''');

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final entityResult = await contextCollection
          .contextFor(entityPath)
          .currentSession
          .getResolvedUnit(entityPath) as ResolvedUnitResult;

      final modelResult = await contextCollection
          .contextFor(modelPath)
          .currentSession
          .getResolvedUnit(modelPath) as ResolvedUnitResult;

      final entityElement = entityResult.unit.declarations.first.declaredFragment!.element as InterfaceElement;
      final modelNode = modelResult.unit.declarations.first as ClassDeclaration;

      final methodSpec = CreateToEntityMethodFix.buildToEntityMethod(
        modelNode: modelNode,
        entityElement: entityElement,
        entityName: 'UserEntity',
      );

      final source = methodSpec.accept(cb.DartEmitter(useNullSafetySyntax: true)).toString();

      expect(source, contains("throw UnimplementedError('TODO: Map field \"email\"')"));
    });
  });
}