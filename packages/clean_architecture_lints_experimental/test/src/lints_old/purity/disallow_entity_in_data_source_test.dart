// test/src/lints/purity/disallow_entity_in_data_source_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/purity/disallow_entity_in_data_source.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowEntityInDataSource Lint', () {
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;

    // Helper to write files safely using canonical paths
    void addFile(String relativePath, String content) {
      final fullPath = p.join(testProjectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      // [Windows Fix] Use canonical path
      tempDir = Directory.systemTemp.createTempSync('entity_in_source_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Create the Entity definition
      addFile('lib/features/user/domain/entities/user.dart', 'class User {}');

      // Create a Model definition
      addFile('lib/features/user/data/models/user_model.dart', 'class UserModel {}');
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
      final lint = DisallowEntityInDataSource(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when DataSource method returns an Entity', () async {
      final path = 'lib/features/user/data/sources/user_remote_source.dart';
      addFile(path, '''
        import '../../domain/entities/user.dart';
        abstract class UserRemoteSource {
          Future<User> getUser(); // VIOLATION
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('DataSources must not depend on or reference domain Entities'));
    });

    test('reports violation when DataSource method accepts an Entity parameter', () async {
      final path = 'lib/features/user/data/sources/user_remote_source.dart';
      addFile(path, '''
        import '../../domain/entities/user.dart';
        abstract class UserRemoteSource {
          Future<void> saveUser(User user); // VIOLATION
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('reports violation when Entity is used in a generic List', () async {
      final path = 'lib/features/user/data/sources/user_remote_source.dart';
      addFile(path, '''
        import '../../domain/entities/user.dart';
        abstract class UserRemoteSource {
          Future<List<User>> getUsers(); // VIOLATION
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('does not report violation when DataSource uses a Model', () async {
      final path = 'lib/features/user/data/sources/user_remote_source.dart';
      addFile(path, '''
        import '../models/user_model.dart';
        abstract class UserRemoteSource {
          Future<UserModel> getUser(); // OK
          Future<void> saveUser(UserModel user); // OK
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('does not report violation when file is not a DataSource', () async {
      // This is a Repository (Domain), where Entities ARE allowed.
      final path = 'lib/features/user/domain/repositories/user_repository.dart';
      addFile(path, '''
        import '../entities/user.dart';
        abstract class UserRepository {
          Future<User> getUser(); // OK
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });
  });
}