import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/file/path_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('PathUtils', () {
    late MemoryResourceProvider provider;
    late String projectRoot;

    setUp(() {
      provider = MemoryResourceProvider();
      // MemoryResourceProvider usually mimics the host OS separator,
      // but we can rely on its pathContext to be consistent.
      projectRoot = provider.convertPath('/my_project');

      // Create the project root and pubspec
      provider.newFolder(projectRoot);
      provider.newFile(provider.pathContext.join(projectRoot, 'pubspec.yaml'), 'name: test');
    });

    /// Helper to quickly create a config for testing
    ArchitectureConfig createConfig({
      String type = 'feature_first',
      String featuresDir = 'features',
      String domainDir = 'domain',
      String usecaseDir = 'usecases',
      String? useCaseNamingPattern,
    }) {
      return ArchitectureConfig.fromMap({
        'module_definitions': {
          'type': type,
          'core': 'core',
          'features': featuresDir,
          'layers': {
            'domain': domainDir,
            'data': 'data',
            'presentation': 'presentation',
          }
        },
        'layer_definitions': {
          'domain': {
            'entity': 'entities',
            'ports': 'ports',
            'usecase': usecaseDir,
          },
          // Other layers required by model but not used in these tests
          'data': {'model': 'models', 'repository': 'repositories', 'source': 'sources'},
          'presentation': {'page': 'pages', 'widget': 'widgets', 'manager': 'managers'},
        },
        'naming_conventions': [
          if (useCaseNamingPattern != null)
            {'on': 'usecase', 'pattern': useCaseNamingPattern}
        ],
        // Empty defaults for required sections
        'inheritances': [],
        'annotations': [],
        'type_safeties': [],
        'dependencies': [],
        'services': {},
        'type_definitions': {},
        'error_handlers': [],
      });
    }

    group('findProjectRoot', () {
      test('finds root when file is deep in the structure', () {
        final deepPath = provider.pathContext.join(
            projectRoot, 'lib', 'features', 'auth', 'data', 'repo.dart');
        provider.newFile(deepPath, '');

        final root = PathUtils.findProjectRoot(deepPath, provider);
        expect(root, equals(projectRoot));
      });

      test('returns null if no pubspec.yaml is found', () {
        // Create a path outside the project
        final outsidePath = provider.convertPath('/other/lib/file.dart');
        provider.newFile(outsidePath, '');

        final root = PathUtils.findProjectRoot(outsidePath, provider);
        expect(root, isNull);
      });

      test('returns root if file is exactly at root (unlikely but possible)', () {
        final rootFile = provider.pathContext.join(projectRoot, 'main.dart');
        provider.newFile(rootFile, '');

        final root = PathUtils.findProjectRoot(rootFile, provider);
        expect(root, equals(projectRoot));
      });
    });

    group('getUseCasesDirectoryPath', () {
      test('Feature First: locates usecase dir inside the specific feature', () {
        final config = createConfig(
          type: 'feature_first',
          featuresDir: 'feats',
          domainDir: 'dom',
          usecaseDir: 'cases',
        );

        final repoPath = provider.pathContext.join(
            projectRoot, 'lib', 'feats', 'auth', 'dom', 'repos', 'repo.dart');

        final result = PathUtils.getUseCasesDirectoryPath(repoPath, config, provider);

        final expected = provider.pathContext.join(
            projectRoot, 'lib', 'feats', 'auth', 'dom', 'cases');

        expect(result, equals(expected));
      });

      test('Layer First: locates usecase dir inside the global domain layer', () {
        final config = createConfig(
          type: 'layer_first',
          domainDir: 'domain_layer',
          usecaseDir: 'use_cases',
        );

        final repoPath = provider.pathContext.join(
            projectRoot, 'lib', 'domain_layer', 'repos', 'repo.dart');

        final result = PathUtils.getUseCasesDirectoryPath(repoPath, config, provider);

        final expected = provider.pathContext.join(
            projectRoot, 'lib', 'domain_layer', 'use_cases');

        expect(result, equals(expected));
      });

      test('Returns null if file is not inside lib', () {
        final config = createConfig();
        final binPath = provider.pathContext.join(projectRoot, 'bin', 'script.dart');

        final result = PathUtils.getUseCasesDirectoryPath(binPath, config, provider);

        expect(result, isNull);
      });
    });

    group('getUseCaseFilePath', () {
      test('Generates standard snake_case file name', () {
        final config = createConfig(useCaseNamingPattern: '{{name}}');
        final repoPath = provider.pathContext.join(
            projectRoot, 'lib', 'features', 'auth', 'domain', 'repos', 'repo.dart');

        final result = PathUtils.getUseCaseFilePath(
          methodName: 'loginUser',
          repoPath: repoPath,
          config: config,
          resourceProvider: provider,
        );

        // loginUser -> LoginUser (Pascal) -> login_user.dart (Snake)
        final expected = provider.pathContext.join(
            projectRoot, 'lib', 'features', 'auth', 'domain', 'usecases', 'login_user.dart');

        expect(result, equals(expected));
      });

      test('Generates file name with suffix if naming pattern requires it', () {
        final config = createConfig(useCaseNamingPattern: '{{name}}UseCase');
        final repoPath = provider.pathContext.join(
            projectRoot, 'lib', 'features', 'auth', 'domain', 'repos', 'repo.dart');

        final result = PathUtils.getUseCaseFilePath(
          methodName: 'getProfile',
          repoPath: repoPath,
          config: config,
          resourceProvider: provider,
        );

        // getProfile -> GetProfile (Pascal) -> GetProfileUseCase (Pattern) -> get_profile_use_case.dart
        final expected = provider.pathContext.join(
            projectRoot, 'lib', 'features', 'auth', 'domain', 'usecases', 'get_profile_use_case.dart');

        expect(result, equals(expected));
      });

      test('Handles Acronyms correctly in file name', () {
        final config = createConfig(useCaseNamingPattern: '{{name}}');
        final repoPath = provider.pathContext.join(
            projectRoot, 'lib', 'features', 'auth', 'domain', 'repos', 'repo.dart');

        final result = PathUtils.getUseCaseFilePath(
          methodName: 'getJSONData',
          repoPath: repoPath,
          config: config,
          resourceProvider: provider,
        );

        // getJSONData -> GetJSONData (Pascal) -> get_json_data.dart (Snake)
        final expected = provider.pathContext.join(
            projectRoot, 'lib', 'features', 'auth', 'domain', 'usecases', 'get_json_data.dart');

        expect(result, equals(expected));
      });
    });
  });
}