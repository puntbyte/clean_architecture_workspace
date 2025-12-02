import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/dependency/disallow_service_locator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowServiceLocator Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('service_locator_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: example');

      final libUri = p.toUri(p.join(testProjectPath, 'lib'));
      addFile('.dart_tool/package_config.json', '''
      {
        "configVersion": 2,
        "packages": [
          {"name": "example", "rootUri": "$libUri", "packageUri": "."},
          {"name": "get_it", "rootUri": "$libUri", "packageUri": "."} 
        ]
      }
      ''');

      // Mock the GetIt library at the root of lib
      addFile('lib/get_it.dart', '''
        class GetIt {
          static final GetIt I = GetIt();
          T get<T>() => throw UnimplementedError();
        }
        final getIt = GetIt.I;
      ''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      Map<String, dynamic>? servicesConfig,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(services: servicesConfig);
      final lint = DisallowServiceLocator(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    // FIX: Removed internal quotes around 'getIt' to avoid CLI regex matching issues
    test('Name Check reports violation for getIt global variable usage', () async {
      const path = 'lib/features/user/domain/usecases/get_user.dart';
      addFile(path, '''
        class GetUser {
          void call() {
            // "getIt" matches default banned names
            final repo = getIt(); // VIOLATION
          }
        }
      ''');

      final lints = await runLint(
        filePath: path,
        servicesConfig: {
          'service_locator': {
            'name': ['getIt'],
          },
        },
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Do not use a service locator'));
    });

    // FIX: Removed internal quotes around 'GetIt.I'
    test('Import Check reports violation for GetIt.I usage via import config', () async {
      const path = 'lib/features/user/presentation/managers/user_bloc.dart';

      // Use relative import to ensure analyzer resolution.
      addFile(path, '''
        import '../../../../get_it.dart';
        
        class UserBloc {
          // "GetIt" class usage is caught because it comes from the banned import
          final repo = GetIt.I.get<dynamic>(); // VIOLATION
        }
      ''');

      final lints = await runLint(
        filePath: path,
        servicesConfig: {
          'service_locator': {
            'name': [], // Empty names to force import check test
            'import': 'package:get_it/get_it.dart',
          },
        },
      );

      expect(lints, isNotEmpty);
      expect(lints.first.message, contains('Do not use a service locator'));
    });

    test('does NOT report violation if name and import do not match', () async {
      const path = 'lib/features/user/domain/usecases/get_user.dart';
      addFile(path, '''
        class GetUser {
          void call() {
            final thing = randomName(); // OK
          }
        }
      ''');

      final lints = await runLint(
        filePath: path,
        servicesConfig: {
          'service_locator': {
            'name': ['getIt'],
          },
        },
      );
      expect(lints, isEmpty);
    });

    test('ignores non-architectural files', () async {
      const path = 'lib/main.dart'; // Not in features/...
      addFile(path, '''
        void main() {
          final loc = getIt(); // OK in main
        }
      ''');

      final lints = await runLint(
        filePath: path,
        servicesConfig: {
          'service_locator': {
            'name': ['getIt'],
          },
        },
      );
      expect(lints, isEmpty);
    });
  });
}
