// test/src/utils/semantic_utils_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/utils/ast/semantic_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('SemanticUtils', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<ClassElement> resolveClassElement(String path, String className) async {
      final resolvedPath = p.normalize(path);
      final unitResult = await contextCollection
          .contextFor(resolvedPath)
          .currentSession
          .getResolvedUnit(resolvedPath) as ResolvedUnitResult;
      return unitResult.unit.declarations
          .whereType<ClassDeclaration>()
          .firstWhere((c) => c.name.lexeme == className)
          .declaredFragment!
          .element;
    }

    setUpAll(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('semantic_utils_test_');
      testProjectPath = p.join(p.normalize(tempDir.path), 'test_project');

      final flutterPackagePath = p.join(p.normalize(tempDir.path), 'flutter_sdk', 'packages', 'flutter');

      // 1. Write all files needed for all tests in this group.
      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(p.join(testProjectPath, '.dart_tool/package_config.json'),
          '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}, {"name": "flutter", "rootUri": "${p.toUri(flutterPackagePath)}", "packageUri": "lib/"}]}');

      // Files for isArchitecturalOverride tests
      writeFile(p.join(testProjectPath, 'lib/features/auth/domain/ports/auth_port.dart'),
          'abstract class AuthRepository { void getUser(); String get userId; }');
      writeFile(p.join(testProjectPath, 'lib/data/base_repo.dart'),
          'abstract class BaseRepo { void commonMethod(); }');
      writeFile(p.join(testProjectPath, 'lib/repo_impl.dart'), '''
        import 'package:test_project/features/auth/domain/ports/auth_port.dart';
        import 'package:test_project/data/base_repo.dart';
        class RepoImpl extends BaseRepo implements AuthRepository { 
          @override void getUser() {} 
          @override String get userId => ""; 
          @override void commonMethod() {}
          void notAnOverride() {}
        }
      ''');

      // Files for isComponent tests
      writeFile(p.join(testProjectPath, 'lib/features/user/domain/entities/user_entity.dart'), 'class UserEntity {}');
      writeFile(p.join(testProjectPath, 'lib/features/user/data/models/user_model.dart'), 'class UserModel {}');
      writeFile(p.join(testProjectPath, 'lib/component_test.dart'), '''
        import 'package:test_project/features/user/domain/entities/user_entity.dart';
        import 'package:test_project/features/user/data/models/user_model.dart';
        class ComponentTest {
          UserEntity? direct;
          List<UserModel>? generic;
          Future<List<UserModel>>? nestedGeneric;
        }
      ''');

      // Files for isFlutterType tests
      writeFile(p.join(flutterPackagePath, 'lib/material.dart'), 'class Color {}');
      writeFile(p.join(testProjectPath, 'lib/flutter_type_test.dart'), '''
        import 'package:flutter/material.dart';
        class FlutterTypeTest {
          Color? direct;
          List<Color>? generic;
        }
      ''');

      // 2. Now that the file system is complete, create the context.
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDownAll(() {
      tempDir.deleteSync(recursive: true);
    });

    group('isArchitecturalOverride', () {
      late LayerResolver layerResolver;
      late ClassElement repoImplClass;

      setUpAll(() async {
        final config = makeConfig(portDir: 'ports');
        layerResolver = LayerResolver(config);
        repoImplClass = await resolveClassElement(p.join(testProjectPath, 'lib/repo_impl.dart'), 'RepoImpl');
      });

      test('should return true when a method overrides a member from a Port', () {
        final method = repoImplClass.methods.firstWhere((m) => m.name == 'getUser');
        expect(SemanticUtils.isArchitecturalOverride(method, layerResolver), isTrue);
      });

      test('should return true when a getter overrides a member from a Port', () {
        final getter = repoImplClass.getGetter('userId');
        expect(getter, isNotNull);
        expect(SemanticUtils.isArchitecturalOverride(getter!, layerResolver), isTrue);
      });

      test('should return false when a method overrides from a non-Port class', () {
        final method = repoImplClass.methods.firstWhere((m) => m.name == 'commonMethod');
        expect(SemanticUtils.isArchitecturalOverride(method, layerResolver), isFalse);
      });

      test('should return false for a method that is not an override', () {
        final method = repoImplClass.methods.firstWhere((m) => m.name == 'notAnOverride');
        expect(SemanticUtils.isArchitecturalOverride(method, layerResolver), isFalse);
      });
    });

    group('isComponent', () {
      late LayerResolver layerResolver;

      setUpAll(() {
        layerResolver = LayerResolver(makeConfig());
      });

      test('should return true when a direct type is the specified component', () async {
        final testClass = await resolveClassElement(p.join(testProjectPath, 'lib/component_test.dart'), 'ComponentTest');
        final fieldType = testClass.fields.firstWhere((f) => f.name == 'direct').type;
        expect(SemanticUtils.isComponent(fieldType, layerResolver, ArchComponent.entity), isTrue);
      });
    });

    group('isFlutterType', () {
      test('should return true when a direct type is from a flutter package', () async {
        final testClass = await resolveClassElement(p.join(testProjectPath, 'lib/flutter_type_test.dart'), 'FlutterTypeTest');
        final fieldType = testClass.fields.firstWhere((f) => f.name == 'direct').type;
        expect(SemanticUtils.isFlutterType(fieldType), isTrue);
      });

      test('should return true when a generic type argument is from a flutter package', () async {
        final testClass = await resolveClassElement(p.join(testProjectPath, 'lib/flutter_type_test.dart'), 'FlutterTypeTest');
        final fieldType = testClass.fields.firstWhere((f) => f.name == 'generic').type;
        expect(SemanticUtils.isFlutterType(fieldType), isTrue);
      });
    });
  });
}