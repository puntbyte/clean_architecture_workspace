// test/src/lints/purity/disallow_entity_in_data_source_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/purity/disallow_entity_in_data_source.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowEntityInDataSource Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint(String filePath) async {
      final config = makeConfig();
      final lint = DisallowEntityInDataSource(config: config, layerResolver: LayerResolver(config));

      final resolvedUnit =
          await contextCollection
                  .contextFor(p.normalize(filePath))
                  .currentSession
                  .getResolvedUnit(p.normalize(filePath))
              as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('entity_in_source_test_');
      projectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(projectPath).createSync(recursive: true);

      writeFile(p.join(projectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(projectPath, '.dart_tool', 'package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
        ''
            '"packageUri": "lib/"}]}',
      );

      // Create the Entity definition so the analyzer can resolve it.
      writeFile(
        p.join(projectPath, 'lib/features/user/domain/entities/user.dart'),
        'class User {}',
      );

      // Create a Model definition.
      writeFile(
        p.join(projectPath, 'lib/features/user/data/models/user_model.dart'),
        'class UserModel {}',
      );

      contextCollection = AnalysisContextCollection(includedPaths: [projectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when DataSource method returns an Entity', () async {
      final path = p.join(projectPath, 'lib/features/user/data/sources/user_remote_source.dart');
      writeFile(path, '''
        import '../../domain/entities/user.dart';
        abstract class UserRemoteSource {
          Future<User> getUser(); // VIOLATION
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'disallow_entity_in_data_source');
      expect(
        lints.first.problemMessage.messageText(includeUrl: false),
        'DataSources must not depend on or reference domain Entities.',
      );
    });

    test('should report violation when DataSource method accepts an Entity parameter', () async {
      final path = p.join(projectPath, 'lib/features/user/data/sources/user_remote_source.dart');
      writeFile(path, '''
        import '../../domain/entities/user.dart';
        abstract class UserRemoteSource {
          Future<void> saveUser(User user); // VIOLATION
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('should report violation when Entity is used in a generic List', () async {
      final path = p.join(projectPath, 'lib/features/user/data/sources/user_remote_source.dart');
      writeFile(path, '''
        import '../../domain/entities/user.dart';
        abstract class UserRemoteSource {
          Future<List<User>> getUsers(); // VIOLATION
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('should NOT report violation when DataSource uses a Model', () async {
      final path = p.join(projectPath, 'lib/features/user/data/sources/user_remote_source.dart');
      writeFile(path, '''
        import '../models/user_model.dart';
        abstract class UserRemoteSource {
          Future<UserModel> getUser(); // OK
          Future<void> saveUser(UserModel user); // OK
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should NOT report violation when file is not a DataSource', () async {
      // This is a Repository, where Entities ARE allowed.
      final path = p.join(
        projectPath,
        'lib/features/user/domain/repositories/user_repository.dart',
      );
      writeFile(path, '''
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
