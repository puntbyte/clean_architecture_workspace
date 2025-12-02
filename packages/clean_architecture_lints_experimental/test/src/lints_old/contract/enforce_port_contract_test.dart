// test/src/lints/contract/enforce_port_contract_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/contract/enforce_port_contract.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforcePortContract Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('port_contract_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: feature_first_example');

      final libUri = p.toUri(p.join(testProjectPath, 'lib'));
      addFile('.dart_tool/package_config.json', '''
      {
        "configVersion": 2,
        "packages": [
          {
            "name": "feature_first_example",
            "rootUri": "$libUri",
            "packageUri": "."
          },
          {
            "name": "clean_architecture_core",
            "rootUri": "../",
            "packageUri": "lib/"
          }
        ]
      }
      ''');

      // Define the Base Port
      addFile('lib/core/port/port.dart', 'abstract interface class Port { const Port(); }');
    });

    tearDown(() {
      try { tempDir.deleteSync(recursive: true); } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit = await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(inheritances: inheritances);
      final lint = EnforcePortContract(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('Default Rule: Valid when Port implements local Port (Relative Import)', () async {
      final path = 'lib/features/auth/domain/ports/auth_port.dart';

      // FIX: Use relative import to guarantee analyzer resolution
      addFile(path, '''
        import '../../../../core/port/port.dart';
        
        // Should PASS: Implements Port
        abstract interface class AuthPort implements Port {}
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('Default Rule: Violation when Port does not implement anything', () async {
      final path = 'lib/features/auth/domain/ports/auth_port.dart';
      addFile(path, '''
        abstract interface class AuthPort {}
      ''');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Port interfaces must extend or implement: Port'));
    });

    test('Custom Rule: Valid when Port implements configured base (Template Match)', () async {
      // Config uses 'example', code uses local relative import.
      // Suffix '/core/port/port.dart' matches.
      final customConfig = [
        {
          'on': 'port',
          'required': {'name': 'Port', 'import': 'package:example/core/port/port.dart'}
        }
      ];

      final path = 'lib/features/auth/domain/ports/auth_port.dart';
      addFile(path, '''
        import '../../../../core/port/port.dart';
        abstract interface class AuthPort implements Port {}
      ''');

      final lints = await runLint(
        filePath: path,
        inheritances: customConfig,
      );

      expect(lints, isEmpty);
    });
  });
}