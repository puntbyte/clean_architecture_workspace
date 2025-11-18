// test/src/utils/path_utils_test.dart

import 'dart:io';

import 'package:clean_architecture_lints/src/utils/path_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('PathUtils', () {
    late Directory tempDir;
    late String projectRoot;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('path_utils_test_');
      projectRoot = tempDir.path;
      await File(p.join(projectRoot, 'pubspec.yaml')).writeAsString('name: test_project');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('findProjectRoot', () {
      test('should find project root when file is deeply nested inside lib', () async {
        final nestedFile = await File(
          p.join(projectRoot, 'lib', 'a', 'b', 'c.dart'),
        ).create(recursive: true);
        final foundRoot = PathUtils.findProjectRoot(nestedFile.path);
        expect(p.normalize(foundRoot!), p.normalize(projectRoot));
      });

      test('should return null when pubspec.yaml is not found in parent directories', () {
        final outsidePath = Directory.systemTemp.path;
        final foundRoot = PathUtils.findProjectRoot(p.join(outsidePath, 'file.dart'));
        expect(foundRoot, isNull);
      });
    });

    group('getUseCasesDirectoryPath', () {
      test('should return correct path for a feature when in a feature-first project', () async {
        final repoFile = await File(
          p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'contracts', 'repo.dart'),
        ).create(recursive: true);
        final config = makeConfig(type: 'feature_first');
        final result = PathUtils.getUseCasesDirectoryPath(repoFile.path, config);
        final expected = p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'usecases');
        expect(p.normalize(result!), p.normalize(expected));
      });

      test('should return correct path for a domain when in a layer-first project', () async {
        final repoFile = await File(
          p.join(projectRoot, 'lib', 'domain', 'contracts', 'repo.dart'),
        ).create(recursive: true);
        final config = makeConfig(type: 'layer_first');
        final result = PathUtils.getUseCasesDirectoryPath(repoFile.path, config);
        final expected = p.join(projectRoot, 'lib', 'domain', 'usecases');
        expect(p.normalize(result!), p.normalize(expected));
      });

      test('should return correct path when usecase directory name is customized', () async {
        final repoFile = await File(
          p.join(projectRoot, 'lib', 'domain', 'contracts', 'repo.dart'),
        ).create(recursive: true);
        final config = makeConfig(type: 'layer_first', usecaseDir: 'domain_actions');
        final result = PathUtils.getUseCasesDirectoryPath(repoFile.path, config);
        final expected = p.join(projectRoot, 'lib', 'domain', 'domain_actions');
        expect(p.normalize(result!), p.normalize(expected));
      });

      test('should return null when path is not inside the lib directory', () async {
        final repoFile = await File(
          p.join(projectRoot, 'test', 'some_repo.dart'),
        ).create(recursive: true);
        final config = makeConfig();
        final result = PathUtils.getUseCasesDirectoryPath(repoFile.path, config);
        expect(result, isNull);
      });
    });

    group('getUseCaseFilePath', () {
      test('should construct full file path when given a method and repo path', () async {
        final repoFile = await File(
          p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'contracts', 'repo.dart'),
        ).create(recursive: true);
        final config = makeConfig(
          namingRules: [
            {'on': 'usecase', 'pattern': '{{name}}Action'},
          ],
        );

        final resultPath = PathUtils.getUseCaseFilePath(
          methodName: 'getUser',
          repoPath: repoFile.path,
          config: config,
        );

        final expectedPath = p.join(
          projectRoot,
          'lib',
          'features',
          'auth',
          'domain',
          'usecases',
          'get_user_action.dart',
        );
        expect(p.normalize(resultPath!), p.normalize(expectedPath));
      });
    });
  });
}
