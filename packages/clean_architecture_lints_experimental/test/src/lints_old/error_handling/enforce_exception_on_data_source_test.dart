// test/src/lints/error_handling/enforce_exception_on_data_source_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/error_handling/'
    'enforce_exception_on_data_source.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceExceptionOnDataSource Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('enforce_exception_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );

      // Define the types referenced in the config
      addFile('lib/core/types.dart', '''
        class FutureEither<L, R> {}
        class Either<L, R> {}
      ''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      Map<String, dynamic>? typeDefinitions,
      List<Map<String, dynamic>>? typeSafeties,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(
        typeDefinitions: typeDefinitions,
        typeSafeties: typeSafeties,
      );

      final lint = EnforceExceptionOnDataSource(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    // --- Config Scenarios ---

    // Scenario 1: Config using Semantic Keys (referencing type_definitions)
    final semanticTypeDefinitions = {
      'result': {
        'wrapper': {'name': 'FutureEither', 'import': 'package:test_project/core/types.dart'},
        'future': {'name': 'Future'},
      },
    };
    final semanticTypeSafeties = [
      {
        'on': ['source'], // source interface & implementation
        'returns': {
          'unsafe_type': 'result.wrapper', // Should resolve to 'FutureEither'
          'safe_type': 'result.future',
        },
      },
    ];

    // Scenario 2: Config using Raw Names (Legacy/Simple support)
    final rawTypeSafeties = [
      {
        'on': ['source'],
        'returns': {'unsafe_type': 'Either', 'safe_type': 'Future'},
      },
    ];

    test('reports violation when return type matches unsafe type via Semantic Key', () async {
      const path = 'lib/features/user/data/sources/user_source.dart';
      addFile(path, '''
        import 'package:test_project/core/types.dart';
        abstract class UserSource {
          // 'FutureEither' corresponds to 'result.wrapper' which is unsafe for 'source'
          FutureEither<Exception, bool> login(); 
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeDefinitions: semanticTypeDefinitions,
        typeSafeties: semanticTypeSafeties,
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('not return wrapper types like `FutureEither`'));
    });

    test('reports violation when return type matches unsafe type via Raw Name', () async {
      const path = 'lib/features/user/data/sources/user_source_impl.dart';
      addFile(path, '''
        import 'package:test_project/core/types.dart';
        class UserSourceImpl {
          // 'Either' is explicitly unsafe in rawTypeSafeties
          Either<Exception, bool> login() => throw UnimplementedError();
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeSafeties: rawTypeSafeties,
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('not return wrapper types like `Either`'));
    });

    test('does not report violation when return type is safe', () async {
      const path = 'lib/features/user/data/sources/user_source.dart';
      addFile(path, '''
        abstract class UserSource {
          Future<String> getToken(); // OK
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeDefinitions: semanticTypeDefinitions,
        typeSafeties: semanticTypeSafeties,
      );
      expect(lints, isEmpty);
    });

    test('does not report violation when type safety config is empty', () async {
      const path = 'lib/features/user/data/sources/user_source.dart';
      addFile(path, '''
        import 'package:test_project/core/types.dart';
        abstract class UserSource {
          FutureEither<Exception, bool> login();
        }
      ''');

      final lints = await runLint(filePath: path, typeSafeties: []);
      expect(lints, isEmpty);
    });

    test('ignores files that are not DataSources (e.g. Repositories)', () async {
      const path = 'lib/features/user/data/repositories/user_repository.dart';
      addFile(path, '''
        import 'package:test_project/core/types.dart';
        class UserRepository {
          // Repositories CAN return FutureEither (defined by other rules, but allowed by this one)
          FutureEither<Exception, bool> login() async => throw UnimplementedError();
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeDefinitions: semanticTypeDefinitions,
        typeSafeties: semanticTypeSafeties,
      );
      expect(lints, isEmpty);
    });
  });
}
