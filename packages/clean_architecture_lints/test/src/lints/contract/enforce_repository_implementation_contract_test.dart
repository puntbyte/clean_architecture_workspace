// test/src/lints/contract/enforce_repository_implementation_contract_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/contract/'
    'enforce_repository_implementation_contract.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceRepositoryImplementationContract Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    void writeFile(String path, String content) {
      final file = resourceProvider.getFile(path);
      Directory(p.dirname(path)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint({
      required String filePath,
      String contractDir = 'contracts',
      String repositoryDir = 'repositories',
    }) async {
      final config = makeConfig(contractDir: contractDir, repositoryDir: repositoryDir);
      final lint = EnforceRepositoryImplementationContract(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final resolvedUnit =
          await contextCollection.contextFor(filePath).currentSession.getResolvedUnit(filePath)
              as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('repo_impl_contract_test_');
      projectPath = p.join(tempDir.path, 'test_project');
      Directory(projectPath).createSync(recursive: true);

      // Create virtual file system
      writeFile(p.join(projectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(projectPath, '.dart_tool', 'package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
        '"packageUri": "lib/"}]}',
      );

      // Create the contract that implementations are expected to implement.
      writeFile(
        p.join(
          projectPath,
          'lib',
          'features',
          'user',
          'domain',
          'contracts',
          'user_repository.dart',
        ),
        'abstract class UserRepository {}',
      );

      contextCollection = AnalysisContextCollection(
        includedPaths: [projectPath],
        resourceProvider: resourceProvider,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when implementation does not implement a contract', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'user',
        'data',
        'repositories',
        'user_repository_impl.dart',
      );
      writeFile(path, 'class UserRepositoryImpl {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_repository_implementation_contract');
    });

    test(
      'should not report violation when implementation correctly implements a contract',
      () async {
        final path = p.join(
          projectPath,
          'lib',
          'features',
          'user',
          'data',
          'repositories',
          'user_repository_impl.dart',
        );
        writeFile(path, '''
        import 'package:test_project/features/user/domain/contracts/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {}
      ''');

        final lints = await runLint(filePath: path);
        expect(lints, isEmpty);
      },
    );

    test('should not report violation when a superclass implements the contract', () async {
      // Define an abstract base class that implements the contract
      writeFile(
        p.join(
          projectPath,
          'lib',
          'features',
          'user',
          'data',
          'repositories',
          'base_repo_impl.dart',
        ),
        '''
        import 'package:test_project/features/user/domain/contracts/user_repository.dart';
        abstract class BaseRepoImpl implements UserRepository {}
        ''',
      );

      // Define a concrete class that extends the base class
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'user',
        'data',
        'repositories',
        'user_repository_impl.dart',
      );
      writeFile(path, '''
        import 'base_repo_impl.dart';
        class UserRepositoryImpl extends BaseRepoImpl {}
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty, reason: 'Transitive implementations are valid.');
    });

    test('should not report violation for an abstract class in the repository layer', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'user',
        'data',
        'repositories',
        'abstract_repo_impl.dart',
      );
      writeFile(path, 'abstract class AbstractRepoImpl {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty, reason: 'Lint should only apply to concrete classes.');
    });

    test('should not run when file is not a repository implementation', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'user',
        'data',
        'models',
        'user_model.dart',
      );
      writeFile(path, 'class UserModel {}');

      final lints = await runLint(filePath: path);
      expect(
        lints,
        isEmpty,
        reason: 'The lint should ignore files not in a repository implementation directory.',
      );
    });
  });
}
