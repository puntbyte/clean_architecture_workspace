import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/contract/enforce_entity_contract.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceEntityContract Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('entity_contract_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: example');
      addFile('.dart_tool/package_config.json', '{"configVersion": 2, "packages": []}');

      // Define the Base Entity
      addFile('lib/core/entity/entity.dart', 'abstract class Entity { const Entity(); }');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      // Debugging: Verify analyzer resolved the supertype
      final classNode = resolvedUnit.unit.declarations.whereType<ClassDeclaration>().firstOrNull;
      if (classNode != null) {
        final element = classNode.declaredFragment?.element;
        if (element != null) {
          // print('[DEBUG] Class: ${element.name}');
          // for(var s in element.allSupertypes) print('  - Super: ${s.element.name}
          // (${s.element.library.source.uri})');
        }
      }

      final config = makeConfig(inheritances: inheritances);
      final lint = EnforceEntityContract(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when entity does not extend anything', () async {
      const path = 'lib/features/user/domain/entities/user.dart';
      addFile(path, 'class User {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Entities must extend or implement: Entity'));
    });

    test('Default Rule: Valid when entity extends local Entity (Relative Import)', () async {
      const path = 'lib/features/user/domain/entities/user.dart';

      // FIX: Use relative import to guarantee resolution
      addFile(path, '''
        import '../../../../core/entity/entity.dart';
        class User extends Entity {
          final String id;
          const User({required this.id});
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test(
      'Custom Rule: Valid when entity extends Configured Base (Exact Match via Relative)',
      () async {
        final customConfig = [
          {
            'on': 'entity',
            'required': {'name': 'Entity', 'import': 'package:example/core/entity/entity.dart'},
          },
        ];

        const path = 'lib/features/user/domain/entities/user.dart';
        addFile(path, '''
        import '../../../../core/entity/entity.dart';
        class User extends Entity {
          final String id;
          const User({required this.id});
        }
      ''');

        final lints = await runLint(filePath: path, inheritances: customConfig);
        expect(lints, isEmpty);
      },
    );

    test(
      'Custom Rule: Valid when entity extends Configured Base (Template/Suffix Match)',
      () async {
        // Config expects 'template_project', code resolves to local file.
        // Suffix matching logic in linter should make this pass.
        final customConfig = [
          {
            'on': 'entity',
            'required': {
              'name': 'Entity',
              'import': 'package:template_project/core/entity/entity.dart',
            },
          },
        ];

        const path = 'lib/features/user/domain/entities/user.dart';
        addFile(path, '''
        import '../../../../core/entity/entity.dart';
        class User extends Entity {
          final String id;
          const User({required this.id});
        }
      ''');

        final lints = await runLint(filePath: path, inheritances: customConfig);
        expect(lints, isEmpty);
      },
    );
  });
}
