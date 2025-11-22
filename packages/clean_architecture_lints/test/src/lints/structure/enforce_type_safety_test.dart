// test/src/lints/structure/enforce_type_safety_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/structure/enforce_type_safety.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceTypeSafety Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('type_safety_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      addFile('lib/core/types.dart', '''
        class FutureEither<L, R> {}
        class UserId {}
      ''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore Windows file lock errors
      }
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> typeSafeties,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(typeSafeties: typeSafeties);
      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    group('Return Type Rules', () {
      final returnRule = {
        'on': 'usecase',
        'returns': {
          'unsafe_type': 'Future',
          'safe_type': 'FutureEither',
          'import': 'package:test_project/core/types.dart',
        },
      };

      test('should report violation when a use case returns an unsafe Future', () async {
        final path = 'lib/features/auth/domain/usecases/login.dart';
        addFile(path, '''
          import 'dart:async';
          class Login {
            Future<bool> call() async => true;
          }
        ''');

        final lints = await runLint(filePath: path, typeSafeties: [returnRule]);
        expect(lints, hasLength(1));
        expect(lints.first.message, contains('return type should be `FutureEither`'));
      });

      test('should not report violation when a use case returns a safe type', () async {
        final path = 'lib/features/auth/domain/usecases/login.dart';
        addFile(path, '''
          import 'package:test_project/core/types.dart';
          class Login {
            FutureEither<Exception, bool> call() => throw UnimplementedError();
          }
        ''');

        final lints = await runLint(filePath: path, typeSafeties: [returnRule]);
        expect(lints, isEmpty);
      });
    });

    group('Parameter Rules', () {
      final parameterRule = {
        // 'port' maps to ArchComponent.port in our config logic
        'on': 'port',
        'parameters': [
          {
            'unsafe_type': 'int',
            'identifier': 'id',
            'safe_type': 'UserId',
            'import': 'package:test_project/core/types.dart',
          },
        ],
      };

      test('should report violation for an unsafe parameter type with matching identifier', () async {
        final path = 'lib/features/user/domain/ports/user_repo.dart';
        addFile(path, '''
          abstract class UserRepo {
            void getUserById(int userId);
          }
        ''');

        final lints = await runLint(filePath: path, typeSafeties: [parameterRule]);
        expect(lints, hasLength(1));
        expect(lints.first.message, contains('parameter `userId` should be of type `UserId`'));
      });

      test('should not report violation for an unsafe type if identifier does not match', () async {
        final path = 'lib/features/user/domain/ports/user_repo.dart';
        addFile(path, '''
          abstract class UserRepo {
            void updateUserAge(int age);
          }
        ''');

        final lints = await runLint(filePath: path, typeSafeties: [parameterRule]);
        expect(lints, isEmpty);
      });

      test('should not report violation when a parameter uses the safe type', () async {
        final path = 'lib/features/user/domain/ports/user_repo.dart';
        addFile(path, '''
          import 'package:test_project/core/types.dart';
          abstract class UserRepo {
            void getUserById(UserId userId);
          }
        ''');

        final lints = await runLint(filePath: path, typeSafeties: [parameterRule]);
        expect(lints, isEmpty);
      });
    });
  });
}