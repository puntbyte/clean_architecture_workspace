// test/src/lints/error_handling/enforce_exception_on_data_source_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/error_handling/'
    'enforce_exception_on_data_source.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceExceptionOnDataSource Lint', () {
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

    Future<List<Diagnostic>> runLint({
      required String filePath,
      List<Map<String, dynamic>>? typeSafeties,
    }) async {
      final config = makeConfig(typeSafeties: typeSafeties);
      final lint = EnforceExceptionOnDataSource(
        config: config,
        layerResolver: LayerResolver(config),
      );

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
      tempDir = Directory.systemTemp.createTempSync('enforce_exception_test_');
      projectPath = p.normalize(tempDir.path);
      final testProjectPath = p.join(projectPath, 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(testProjectPath, '.dart_tool/package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
        '"packageUri": "lib/"}]}',
      );

      // Define the "safe type" that should be forbidden in DataSources.
      writeFile(p.join(testProjectPath, 'lib/core/either.dart'), 'class Either<L, R> {}');

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    String testProjectPath() => p.join(projectPath, 'test_project');

    // The type safety config that defines `Either` as a forbidden return type.
    final typeSafetyConfig = [
      {
        'on': ['usecase', 'repository'],
        // Not relevant for this test, but needed for a valid config
        'returns': {
          'unsafe_type': 'Future',
          'safe_type': 'Either',
          'import': 'package:test_project/core/either.dart',
        },
      },
    ];

    test('should report violation when a data source interface returns a forbidden type', () async {
      final path = p.join(testProjectPath(), 'lib/features/user/data/sources/user_source.dart');
      writeFile(path, '''
        import 'package:test_project/core/either.dart';
        abstract class UserSource {
          Future<Either<Exception, bool>> login();
        }
      ''');

      final lints = await runLint(filePath: path, typeSafeties: typeSafetyConfig);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_exception_on_data_source');
    });

    test(
      'should report violation when a data source implementation returns a forbidden type',
      () async {
        final path = p.join(
          testProjectPath(),
          'lib/features/user/data/sources/user_source_impl.dart',
        );
        writeFile(path, '''
        import 'package:test_project/core/either.dart';
        class UserSourceImpl {
          Either<Exception, bool> login() => throw UnimplementedError();
        }
      ''');

        final lints = await runLint(filePath: path, typeSafeties: typeSafetyConfig);
        expect(lints, hasLength(1));
      },
    );

    test('should not report violation when a data source returns a valid type', () async {
      final path = p.join(testProjectPath(), 'lib/features/user/data/sources/user_source.dart');
      writeFile(path, '''
        abstract class UserSource {
          Future<String> getToken();
        }
      ''');

      final lints = await runLint(filePath: path, typeSafeties: typeSafetyConfig);
      expect(lints, isEmpty);
    });

    test('should not report violation when type_safeties config is empty', () async {
      final path = p.join(testProjectPath(), 'lib/features/user/data/sources/user_source.dart');
      writeFile(path, '''
        import 'package:test_project/core/either.dart';
        abstract class UserSource {
          Future<Either<Exception, bool>> login();
        }
      ''');

      // Run with no type safety config.
      final lints = await runLint(filePath: path, typeSafeties: []);
      expect(lints, isEmpty);
    });

    test('should not report violation when a repository returns a forbidden type', () async {
      final path = p.join(
        testProjectPath(),
        'lib/features/user/data/repositories/user_repository.dart',
      );
      writeFile(path, '''
        import 'package:test_project/core/either.dart';
        class UserRepository {
          Future<Either<Exception, bool>> login() async => throw UnimplementedError();
        }
      ''');

      final lints = await runLint(filePath: path, typeSafeties: typeSafetyConfig);
      expect(lints, isEmpty, reason: 'Lint should only run on DataSource files.');
    });
  });
}
