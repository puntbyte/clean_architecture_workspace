// test/src/utils/semantic_utils_test.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/utils/semantic_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('SemanticUtils', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    void writeFile(String path, String content) {
      final file = resourceProvider.getFile(path);
      file.parent.create();
      file.writeAsStringSync(content);
    }

    Future<ClassElement> resolveClassElement(String path, String className) async {
      final context = contextCollection.contextFor(path);
      final unitResult = await context.currentSession.getResolvedUnit(path) as ResolvedUnitResult;
      return unitResult.unit.declarations
          .whereType<ClassDeclaration>()
          .firstWhere((c) => c.name.lexeme == className)
          .declaredFragment!
          .element;
    }

    setUpAll(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('semantic_utils_test_');
      projectPath = p.join(tempDir.path, 'project');
      final packagesPath = p.join(tempDir.path, 'packages');
      final projectLib = p.join(projectPath, 'lib');

      // Create a virtual file system structure for the analyzer
      writeFile(
        p.join(projectPath, '.dart_tool', 'package_config.json'),
        '''
        {
          "configVersion": 2,
          "packages": [
            { "name": "test_project", "rootUri": "../", "packageUri": "lib/" },
            { "name": "flutter", "rootUri": "${p.toUri(p.join(packagesPath, 'flutter'))}", "packageUri": "lib/" }
          ]
        }
        ''',
      );

      // Create virtual source files
      writeFile(
        p.join(projectLib, 'features', 'auth', 'domain', 'contracts', 'auth_repo.dart'),
        'abstract interface class AuthRepo { void getUser(); String get userId; }',
      );
      writeFile(
        p.join(projectLib, 'features', 'auth', 'domain', 'entities', 'user_entity.dart'),
        'class UserEntity {}',
      );
      writeFile(
        p.join(projectLib, 'features', 'auth', 'data', 'models', 'user_model.dart'),
        'class UserModel {}',
      );
      writeFile(
        p.join(projectLib, 'data', 'base_repo.dart'),
        'abstract class BaseRepo { void commonMethod(); }',
      );
      writeFile(p.join(packagesPath, 'flutter', 'lib', 'material.dart'), 'class Color {}');

      contextCollection = AnalysisContextCollection(
        includedPaths: [projectPath],
        resourceProvider: resourceProvider,
      );
    });

    tearDownAll(() {
      tempDir.deleteSync(recursive: true);
    });

    group('isArchitecturalOverride', () {
      late LayerResolver layerResolver;
      late ClassElement repoImplClass;

      setUpAll(() async {
        layerResolver = LayerResolver(makeConfig());
        final path = p.join(projectPath, 'lib', 'repo_impl.dart');
        writeFile(path, '''
          import 'package:test_project/features/auth/domain/contracts/auth_repo.dart';
          import 'package:test_project/data/base_repo.dart';
          class RepoImpl extends BaseRepo implements AuthRepo { 
            @override void getUser() {} 
            @override String get userId => ""; 
            @override void commonMethod() {}
          }
        ''');
        repoImplClass = await resolveClassElement(path, 'RepoImpl');
      });

      test('should return true when method overrides a member from a domain contract', () {
        final method = repoImplClass.methods.firstWhere((m) => m.name == 'getUser');
        expect(SemanticUtils.isArchitecturalOverride(method, layerResolver), isTrue);
      });

      test('should return true when getter overrides a member from a domain contract', () {
        final getter = repoImplClass.getGetter('userId');
        expect(getter, isNotNull);
        expect(SemanticUtils.isArchitecturalOverride(getter!, layerResolver), isTrue);
      });

      test('should return false when method overrides a member from a non-contract superclass', () {
        final method = repoImplClass.methods.firstWhere((m) => m.name == 'commonMethod');
        expect(SemanticUtils.isArchitecturalOverride(method, layerResolver), isFalse);
      });
    });

    group('isComponent', () {
      late LayerResolver layerResolver;
      setUpAll(() => layerResolver = LayerResolver(makeConfig()));

      test('should return true when a direct type is the specified component', () async {
        final path = p.join(projectPath, 'lib', 'a.dart');
        writeFile(path, '''
          import 'package:test_project/features/auth/domain/entities/user_entity.dart';
          class A { UserEntity? user; }
        ''');
        final classA = await resolveClassElement(path, 'A');
        final fieldType = classA.fields.first.type;
        expect(SemanticUtils.isComponent(fieldType, layerResolver, ArchComponent.entity), isTrue);
      });

      test('should return true when a generic type argument is the specified component', () async {
        final path = p.join(projectPath, 'lib', 'b.dart');
        writeFile(path, '''
          import 'package:test_project/features/auth/data/models/user_model.dart';
          class B { List<UserModel>? models; }
        ''');
        final classB = await resolveClassElement(path, 'B');
        final fieldType = classB.fields.first.type;
        expect(SemanticUtils.isComponent(fieldType, layerResolver, ArchComponent.model), isTrue);
      });

      test(
        'should return true when a nested generic type argument is the specified component',
        () async {
          final path = p.join(projectPath, 'lib', 'c.dart');
          writeFile(path, '''
          import 'package:test_project/features/auth/data/models/user_model.dart';
          class C { Future<List<UserModel>>? models; }
        ''');
          final classC = await resolveClassElement(path, 'C');
          final fieldType = classC.fields.first.type;
          expect(SemanticUtils.isComponent(fieldType, layerResolver, ArchComponent.model), isTrue);
        },
      );
    });

    group('isFlutterType', () {
      test('should return true when a direct type is from a flutter package', () async {
        final path = p.join(projectPath, 'lib', 'd.dart');
        writeFile(path, '''
          import 'package:flutter/material.dart';
          class D { Color? color; }
        ''');
        final classD = await resolveClassElement(path, 'D');
        final fieldType = classD.fields.first.type;
        expect(SemanticUtils.isFlutterType(fieldType), isTrue);
      });

      test('should return true when a generic type argument is from a flutter package', () async {
        final path = p.join(projectPath, 'lib', 'e.dart');
        writeFile(path, '''
          import 'package:flutter/material.dart';
          class E { List<Color>? colors; }
        ''');
        final classE = await resolveClassElement(path, 'E');
        final fieldType = classE.fields.first.type;
        expect(SemanticUtils.isFlutterType(fieldType), isTrue);
      });
    });
  });
}
