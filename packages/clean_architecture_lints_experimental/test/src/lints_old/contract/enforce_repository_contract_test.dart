// test/src/lints/contract/enforce_repository_contract_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/contract/enforce_repository_contract.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceRepositoryContract Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('repo_impl_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );

      // Create the Port (Interface) in the Domain layer
      // By default, 'ports' is the configured directory for domain contracts
      addFile(
        'lib/features/user/domain/ports/user_repository.dart',
        'abstract class UserRepository {}',
      );
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
      // We use default config names (ports/repositories), but allow override for edge cases
      String portDir = 'ports',
      String repositoryDir = 'repositories',
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(portDir: portDir, repositoryDir: repositoryDir);
      final lint = EnforceRepositoryContract(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when implementation does not implement a Port', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, 'class UserRepositoryImpl {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(
        lints.first.message,
        contains('Repository implementations must implement a Port interface'),
      );
    });

    test('reports no violation when implementation correctly implements a Port', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {}
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('reports no violation when a superclass implements the Port (transitive)', () async {
      // Base class implements Port
      addFile(
        'lib/features/user/data/repositories/base_repo_impl.dart',
        '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        abstract class BaseRepoImpl implements UserRepository {}
        ''',
      );

      // Implementation extends Base, inheriting the interface check
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'base_repo_impl.dart';
        class UserRepositoryImpl extends BaseRepoImpl {}
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('ignores abstract classes in the repository layer', () async {
      const path = 'lib/features/user/data/repositories/abstract_repo_impl.dart';
      addFile(path, 'abstract class AbstractRepoImpl {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('ignores files not in a repository implementation directory', () async {
      const path = 'lib/features/user/data/models/user_model.dart';
      addFile(path, 'class UserModel {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}
