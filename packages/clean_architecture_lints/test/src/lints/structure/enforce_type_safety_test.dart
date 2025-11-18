// test/srcs/lints/structure/enforce_type_safety_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/structure/enforce_type_safety.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceTypeSafety Lint', () {
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

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> typeSafeties,
    }) async {
      final config = makeConfig(typeSafeties: typeSafeties);
      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));

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
      tempDir = Directory.systemTemp.createTempSync('type_safety_test_');
      testProjectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(p.join(testProjectPath, 'lib/core/types.dart'), '''
        class FutureEither<L, R> {}
        class UserId {}
      ''');
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

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
        final path = p.join(testProjectPath, 'lib/features/auth/domain/usecases/login.dart');
        writeFile(path, '''
          import 'dart:async';
          class Login {
            Future<bool> call() async => true;
          }
        ''');

        final lints = await runLint(filePath: path, typeSafeties: [returnRule]);
        expect(lints, hasLength(1));
        expect(lints.first.diagnosticCode.name, 'enforce_type_safety_return');
        expect(
          lints.first.problemMessage.messageText(includeUrl: false),
          'The return type should be `FutureEither`, not `Future`.',
        );
      });

      test('should not report violation when a use case returns a safe type', () async {
        final path = p.join(testProjectPath, 'lib/features/auth/domain/usecases/login.dart');
        writeFile(path, '''
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
        'on': 'contract',
        'parameters': [
          {
            'unsafe_type': 'int',
            'identifier': 'id',
            'safe_type': 'UserId',
            'import': 'package:test_project/core/types.dart',
          },
        ],
      };

      test(
        'should report violation for an unsafe parameter type with matching identifier',
        () async {
          final path = p.join(testProjectPath, 'lib/features/user/domain/contracts/user_repo.dart');
          writeFile(path, '''
          abstract class UserRepo {
            void getUserById(int userId);
          }
        ''');

          final lints = await runLint(filePath: path, typeSafeties: [parameterRule]);
          expect(lints, hasLength(1));
          expect(lints.first.diagnosticCode.name, 'enforce_type_safety_parameter');
          expect(
            lints.first.problemMessage.messageText(includeUrl: false),
            'The parameter `userId` should be of type `UserId`, not `int`.',
          );
        },
      );

      test('should not report violation for an unsafe type if identifier does not match', () async {
        final path = p.join(testProjectPath, 'lib/features/user/domain/contracts/user_repo.dart');
        writeFile(path, '''
          abstract class UserRepo {
            void updateUserAge(int age);
          }
        ''');

        final lints = await runLint(filePath: path, typeSafeties: [parameterRule]);
        expect(lints, isEmpty);
      });

      test('should not report violation when a parameter uses the safe type', () async {
        final path = p.join(testProjectPath, 'lib/features/user/domain/contracts/user_repo.dart');
        writeFile(path, '''
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
