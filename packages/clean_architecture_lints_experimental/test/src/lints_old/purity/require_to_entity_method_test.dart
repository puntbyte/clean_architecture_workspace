// test/src/lints/purity/require_to_entity_method_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/purity/require_to_entity_method.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('RequireToEntityMethod Lint', () {
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;

    void addFile(String relativePath, String content) {
      final fullPath = p.join(testProjectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      // [Windows Fix] Use canonical path
      tempDir = Directory.systemTemp.createTempSync('require_to_entity_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Define Entity
      addFile('lib/features/user/domain/entities/user.dart', 'class User {}');
      // Define Unrelated Entity
      addFile('lib/features/product/domain/entities/product.dart', 'class Product {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore Windows file lock errors
      }
    });

    Future<List<Diagnostic>> runLint(String filePath) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig();
      final lint = RequireToEntityMethod(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when toEntity method is missing', () async {
      final path = 'lib/features/user/data/models/user_model.dart';
      addFile(path, '''
        import 'package:test_project/features/user/domain/entities/user.dart';
        class UserModel extends User {}
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('must have a `toEntity()` method'));
    });

    test('reports violation when toEntity method has the wrong return type', () async {
      final path = 'lib/features/user/data/models/user_model.dart';
      addFile(path, '''
        import 'package:test_project/features/user/domain/entities/user.dart';
        import 'package:test_project/features/product/domain/entities/product.dart';
        
        class UserModel extends User {
          Product toEntity() => Product(); // VIOLATION: Should return User
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('does not report violation for a correctly implemented toEntity method', () async {
      final path = 'lib/features/user/data/models/user_model.dart';
      addFile(path, '''
        import 'package:test_project/features/user/domain/entities/user.dart';
        
        class UserModel extends User {
          User toEntity() => User();
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('does not report violation for a model that does not extend an entity', () async {
      // If it doesn't extend an Entity, the rule doesn't apply (e.g. purely internal API model).
      final path = 'lib/features/user/data/models/auth_response_model.dart';
      addFile(path, 'class AuthResponseModel {}');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('ignores files that are not models', () async {
      // This file is in 'domain/entities', so it is an Entity, not a Model.
      final path = 'lib/features/user/domain/entities/user.dart';
      addFile(path, 'class UserModel extends User { User toEntity() => User(); }');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });
  });
}