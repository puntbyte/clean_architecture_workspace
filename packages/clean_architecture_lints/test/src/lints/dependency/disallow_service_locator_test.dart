// test/src/lints/dependency/disallow_service_locator_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/dependency/disallow_service_locator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowServiceLocator Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('service_locator_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
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
      List<String> locatorNames = const ['getIt', 'sl'],
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      // Configure the lint with specific locator names
      final config = makeConfig(
        services: {
          'dependency_injection': {'name': locatorNames}
        },
      );

      final lint = DisallowServiceLocator(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when using getIt() as a method call', () async {
      final path = 'lib/features/user/domain/usecases/get_user.dart';
      addFile(path, '''
        class GetUser {
          void call() {
            final repo = getIt(); // VIOLATION
          }
        }
      ''');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Do not use a service locator'));
    });

    test('reports violation when using sl as a property/instance', () async {
      final path = 'lib/features/user/presentation/managers/user_bloc.dart';
      addFile(path, '''
        class UserBloc {
          final repo = sl<UserRepository>(); // VIOLATION
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, hasLength(1));
    });

    test('reports violation for custom locator names configured in options', () async {
      final path = 'lib/features/user/data/repositories/repo_impl.dart';
      addFile(path, '''
        class RepoImpl {
          final source = locator(); // VIOLATION (if configured)
        }
      ''');

      // Run with 'locator' as the banned name
      final lints = await runLint(
        filePath: path,
        locatorNames: ['locator'],
      );
      expect(lints, hasLength(1));
    });

    test('does NOT report violation if the name is not in the config', () async {
      final path = 'lib/features/user/domain/usecases/get_user.dart';
      addFile(path, '''
        class GetUser {
          void call() {
            final thing = randomName(); // OK
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('does NOT report violation in unknown/non-architectural files', () async {
      // 'injection_container.dart' is usually in the root or a core folder
      // that is not mapped to a specific strict layer in our default config.
      final path = 'lib/injection_container.dart';
      addFile(path, '''
        final getIt = GetIt.instance;
        
        void init() {
          getIt.registerFactory(() => MyBloc()); // OK here
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(
        lints,
        isEmpty,
        reason: 'The dependency injection setup file should be allowed to use the locator.',
      );
    });
  });
}