// test/src/lints/purity/enforce_contract_api_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/purity/enforce_contract_api.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceContractApi Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('enforce_contract_api_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Define the contract (Port)
      addFile(
        'lib/features/user/domain/ports/user_repository.dart',
        '''
        abstract class UserRepository {
          void fetchUser(String id);
          String get userName;
        }
        ''',
      );
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
      final lint = EnforceContractApi(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation for a public method not in the contract', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {
          @override
          void fetchUser(String id) {}

          @override
          String get userName => 'test';
          
          void publicHelper() {} // VIOLATION: Leaking implementation detail
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('public member `publicHelper` is not defined'));
    });

    test('reports violation for a public field not in the contract', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {
          final String publicField = 'oops'; // VIOLATION
          
          @override
          void fetchUser(String id) {}

          @override
          String get userName => publicField;
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('does not report violation for members that are in the contract', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {
          @override
          void fetchUser(String id) {}

          @override
          String get userName => 'test';
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('does not report violation for private members', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {
          @override
          void fetchUser(String id) => _privateHelper();

          @override
          String get userName => 'test';
          
          void _privateHelper() {} // OK
          final String _privateField = ''; // OK
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('does not report violation for constructors', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {
          UserRepositoryImpl(); // OK
          
          @override
          void fetchUser(String id) {}

          @override
          String get userName => 'test';
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });
  });
}