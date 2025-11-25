import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/structure/enforce_annotations.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceAnnotations Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('enforce_annotations_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: example');
      final libUri = p.toUri(p.join(testProjectPath, 'lib'));
      addFile('.dart_tool/package_config.json', '''
      {
        "configVersion": 2,
        "packages": [
          {"name": "example", "rootUri": "$libUri", "packageUri": "."},
          {"name": "injectable", "rootUri": "$libUri", "packageUri": "."} 
        ]
      }
      ''');

      // Define dummy annotations
      addFile('lib/injectable.dart', '''
        class Injectable { const Injectable(); }
        class LazySingleton { const LazySingleton(); }
      ''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> annotations,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(annotations: annotations);
      final lint = EnforceAnnotations(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    group('Forbidden Rule', () {
      test('flags Usage AND Import when import is defined in config', () async {
        final forbiddenRule = {
          'on': 'entity',
          'forbidden': {
            'name': ['Injectable', 'LazySingleton'],
            'import': 'package:injectable/injectable.dart',
          },
        };

        const path = 'lib/features/user/domain/entities/user.dart';
        addFile(path, '''
          import 'package:injectable/injectable.dart'; 
          
          @Injectable()
          @LazySingleton()
          class User {}
        ''');

        final lints = await runLint(filePath: path, annotations: [forbiddenRule]);

        expect(lints, hasLength(3));

        expect(
          lints.any(
            (l) => l.message.contains('import `package:injectable/injectable.dart` is forbidden'),
          ),
          isTrue,
        );
        expect(
          lints.any((l) => l.message.contains('must not have the `@Injectable` annotation')),
          isTrue,
        );
        expect(
          lints.any((l) => l.message.contains('must not have the `@LazySingleton` annotation')),
          isTrue,
        );
      });

      test('flags Usage ONLY when import is NOT defined in config', () async {
        final forbiddenRule = {
          'on': 'entity',
          'forbidden': {'name': 'Injectable'},
        };

        const path = 'lib/features/user/domain/entities/user.dart';
        addFile(path, '''
          import 'package:injectable/injectable.dart';
          @Injectable()
          class User {}
        ''');

        final lints = await runLint(filePath: path, annotations: [forbiddenRule]);

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('must not have the `@Injectable` annotation'));
      });
    });

    group('Required Rule', () {
      test('reports violation when required annotation is missing', () async {
        final requiredRule = {
          'on': 'usecase',
          'required': {'name': 'Injectable'},
        };

        const path = 'lib/features/auth/domain/usecases/login.dart';
        addFile(path, 'class Login {}');

        final lints = await runLint(filePath: path, annotations: [requiredRule]);

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('missing the required `@Injectable` annotation'));
      });
    });
  });
}
