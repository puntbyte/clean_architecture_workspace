import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/error_handling/convert_exceptions_to_failures.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('ConvertExceptionsToFailures Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('convert_exceptions_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );

      // Setup types
      addFile('lib/core/error/exceptions.dart', '''
        class ServerException implements Exception {}
        class CacheException implements Exception {}
      ''');
      addFile('lib/core/error/failures.dart', '''
        class Failure {}
        class ServerFailure extends Failure {}
        class CacheFailure extends Failure {}
      ''');
      addFile('lib/core/utils/types.dart', 'class Left<L, R> { const Left(L l); }');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({required String filePath}) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      // Configure with Types and Conversions
      final config = makeConfig(
        typeDefinitions: {
          'exception': {
            'server': {
              'name': 'ServerException',
              'import': 'package:test_project/core/error/exceptions.dart',
            },
            'cache': {
              'name': 'CacheException',
              'import': 'package:test_project/core/error/exceptions.dart',
            },
          },
          'failure': {
            'server': {
              'name': 'ServerFailure',
              'import': 'package:test_project/core/error/failures.dart',
            },
            'cache': {
              'name': 'CacheFailure',
              'import': 'package:test_project/core/error/failures.dart',
            },
          },
        },
        errorHandlers: [
          {
            'on': 'repository',
            'role': 'boundary',
            'conversions': [
              // Rule: ServerException -> ServerFailure
              {'from_type': 'exception.server', 'to_type': 'failure.server'},
              // Rule: CacheException -> CacheFailure
              {'from_type': 'exception.cache', 'to_type': 'failure.cache'},
            ],
          },
        ],
      );

      final lint = ConvertExceptionsToFailures(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when catching ServerException but returning CacheFailure', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/core/error/exceptions.dart';
        import 'package:test_project/core/error/failures.dart';
        import 'package:test_project/core/utils/types.dart';

        class UserRepositoryImpl {
          void getUser() {
            try {
              // ...
            } on ServerException catch (e) {
              // VIOLATION: Should return ServerFailure
              return Left(CacheFailure()); 
            }
          }
        }
      ''');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(
        lints.first.message,
        contains('Expected to return `ServerFailure` when catching `ServerException`'),
      );
    });

    test('does NOT report violation when mapping is correct', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/core/error/exceptions.dart';
        import 'package:test_project/core/error/failures.dart';
        import 'package:test_project/core/utils/types.dart';

        class UserRepositoryImpl {
          void getUser() {
            try {
              // ...
            } on ServerException catch (e) {
              // CORRECT
              return Left(ServerFailure()); 
            }
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('reports violation when multiple returns exist and one is wrong', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/core/error/exceptions.dart';
        import 'package:test_project/core/error/failures.dart';
        import 'package:test_project/core/utils/types.dart';

        class UserRepositoryImpl {
          void getUser() {
            try {
            } on ServerException catch (e) {
              if (true) {
                 return Left(ServerFailure()); // OK
              }
              // VIOLATION
              return Left(CacheFailure()); 
            }
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, hasLength(1));
    });

    test('ignores exceptions not defined in the conversion rules', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        class UserRepositoryImpl {
          void getUser() {
            try {
            } on FormatException catch (e) {
              // No rule for FormatException, so linter ignores this block
              return; 
            }
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}
