// test/src/lints/structure/missing_use_case_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/structure/missing_use_case.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('MissingUseCase Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('missing_usecase_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );
    });

    tearDown(() {
      try { tempDir.deleteSync(recursive: true); } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig();
      final lint = MissingUseCase(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when a repository method is missing its use case file', () async {
      final path = 'lib/features/auth/domain/ports/auth_repository.dart';
      addFile(path, '''
        abstract class AuthRepository {
          Future<void> login(String email); // VIOLATION
        }
      ''');

      // No corresponding UseCase file created.

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('missing the corresponding `Login` UseCase'));
    });

    test('does not report violation when use case file exists', () async {
      final repoPath = 'lib/features/auth/domain/ports/auth_repository.dart';
      addFile(repoPath, '''
        abstract class AuthRepository {
          Future<void> login(String email); // OK, file exists
        }
      ''');

      // Create the corresponding use case
      // Default config expects: lib/features/auth/domain/usecases/login.dart
      addFile('lib/features/auth/domain/usecases/login.dart', 'class Login {}');

      final lints = await runLint(filePath: repoPath);
      expect(lints, isEmpty);
    });

    test('ignores getters, setters, and private methods', () async {
      final path = 'lib/features/auth/domain/ports/auth_repository.dart';
      addFile(path, '''
        abstract class AuthRepository {
          String get userId;
          set user(String user);
          void _privateHelper();
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}