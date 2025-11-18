// test/srcs/lints/structure/missing_use_case_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/structure/missing_use_case.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('MissingUseCase Lint', () {
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

    Future<List<Diagnostic>> runLint(String filePath) async {
      final config = makeConfig();
      final lint = MissingUseCase(config: config, layerResolver: LayerResolver(config));

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
      tempDir = Directory.systemTemp.createTempSync('missing_use_case_test_');
      testProjectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(testProjectPath, '.dart_tool/package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
        '"packageUri": "lib/"}]}',
      );

      // FIX: The includedPaths for the collection MUST be the project root,
      // not a subdirectory like 'lib'. This allows the analyzer to find
      // pubspec.yaml and establish the context correctly for all sub-files.
      contextCollection = AnalysisContextCollection(
        includedPaths: [testProjectPath],
        resourceProvider: resourceProvider,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when a repository method is missing its use case file', () async {
      final repoPath = p.join(
        testProjectPath,
        'lib/features/auth/domain/contracts/auth_repository.dart',
      );
      writeFile(repoPath, '''
        abstract class AuthRepository {
          Future<void> login(String email);
          Future<void> logout();
        }
      ''');

      final logoutUseCasePath = p.join(
        testProjectPath,
        'lib/features/auth/domain/usecases/logout.dart',
      );
      writeFile(logoutUseCasePath, 'class Logout {}');

      final lints = await runLint(repoPath);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'missing_use_case');
      expect(
        lints.first.problemMessage.messageText(includeUrl: false),
        'The repository method `login` is missing the corresponding `Login` UseCase.',
      );
    });

    test(
      'should not report violation when all methods have corresponding use case files',
      () async {
        final repoPath = p.join(
          testProjectPath,
          'lib/features/auth/domain/contracts/auth_repository.dart',
        );
        writeFile(repoPath, '''
        abstract class AuthRepository {
          Future<void> login(String email);
        }
      ''');

        final loginUseCasePath = p.join(
          testProjectPath,
          'lib/features/auth/domain/usecases/login.dart',
        );
        writeFile(loginUseCasePath, 'class Login {}');

        final lints = await runLint(repoPath);
        expect(lints, isEmpty);
      },
    );

    test('should ignore getters, setters, and private methods', () async {
      final repoPath = p.join(
        testProjectPath,
        'lib/features/auth/domain/contracts/auth_repository.dart',
      );
      writeFile(repoPath, '''
        abstract class AuthRepository {
          String get userId;
          set user(String user);
          void _privateHelper();
        }
      ''');

      final lints = await runLint(repoPath);
      expect(lints, isEmpty);
    });

    test('should not run on files that are not repository contracts', () async {
      final repoImplPath = p.join(
        testProjectPath,
        'lib/features/auth/data/repositories/auth_repository_impl.dart',
      );
      writeFile(repoImplPath, '''
        class AuthRepositoryImpl {
          void login() {}
        }
      ''');

      final lints = await runLint(repoImplPath);
      expect(lints, isEmpty);
    });
  });
}
