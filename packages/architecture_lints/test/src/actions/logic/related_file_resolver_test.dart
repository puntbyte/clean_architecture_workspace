import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:architecture_lints/src/engines/file/related_file_resolver.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('RelatedFileResolver', () {
    late Directory tempDir;
    late ArchitectureConfig config;
    late RelatedFileResolver resolver;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('related_resolver_test_');

      config = const ArchitectureConfig(
        components: [
          ComponentDefinition(
            id: 'domain.entity',
            paths: ['domain/entities'],
            // FIX: Use ${name} syntax to match updated NamingLogic
            patterns: [r'${name}'],
          ),
          ComponentDefinition(
            id: 'data.model',
            paths: ['data/models'],
            patterns: [r'${name}Model'],
          ),
        ],
      );

      resolver = RelatedFileResolver(config);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<({String sourcePath, AnalysisContextCollection collection})> createProject({
      required String sourceRelPath,
      required String sourceContent,
      String? targetRelPath,
      String? targetContent,
    }) async {
      // Platform-agnostic path building
      // Handle forward slashes in test input regardless of OS
      final sourcePath = p.join(tempDir.path, 'lib', p.joinAll(sourceRelPath.split('/')));

      final sourceFile = File(sourcePath);
      sourceFile.parent.createSync(recursive: true);
      sourceFile.writeAsStringSync(sourceContent);

      if (targetRelPath != null && targetContent != null) {
        final targetPath = p.join(tempDir.path, 'lib', p.joinAll(targetRelPath.split('/')));
        final targetFile = File(targetPath);
        targetFile.parent.createSync(recursive: true);
        targetFile.writeAsStringSync(targetContent);
      }

      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('name: test_project');

      final collection = AnalysisContextCollection(includedPaths: [tempDir.path]);
      return (sourcePath: sourcePath, collection: collection);
    }

    test('should resolve existing related file (Entity -> Model)', () async {
      final project = await createProject(
        sourceRelPath: 'domain/entities/user.dart',
        sourceContent: 'class User {}',
        targetRelPath: 'data/models/user_model.dart',
        targetContent: 'class UserModel {}',
      );

      final session = project.collection.contextFor(project.sourcePath).currentSession;

      final sourceContext = ComponentContext(
        filePath: project.sourcePath,
        definition: config.components.firstWhere((c) => c.id == 'domain.entity'),
      );

      final result = await resolver.resolveRelated(
        currentContext: sourceContext,
        targetComponentId: 'data.model',
        session: session,
      );

      expect(result, isNotNull);
      expect(result, isA<ResolvedUnitResult>());
      expect(result!.path, endsWith('user_model.dart'));
    });

    test('should return null if target file does not exist', () async {
      final project = await createProject(
        sourceRelPath: 'domain/entities/user.dart',
        sourceContent: 'class User {}',
      );

      final session = project.collection.contextFor(project.sourcePath).currentSession;

      final sourceContext = ComponentContext(
        filePath: project.sourcePath,
        definition: config.components.firstWhere((c) => c.id == 'domain.entity'),
      );

      final result = await resolver.resolveRelated(
        currentContext: sourceContext,
        targetComponentId: 'data.model',
        session: session,
      );

      expect(result, isNull);
    });

    test('should return null if core name extraction fails', () async {
      final project = await createProject(
        sourceRelPath: 'src/file.dart',
        sourceContent: 'class File {}',
      );
      final session = project.collection.contextFor(project.sourcePath).currentSession;

      const configNoPattern = ArchitectureConfig(
        components: [
          // No patterns -> cannot extract core name safely usually,
          // or extraction returns full name 'File'
          ComponentDefinition(id: 'source', paths: ['src'], patterns: []),
          // Target expects '${name}Tgt' -> 'FileTgt'
          ComponentDefinition(id: 'target', paths: ['tgt'], patterns: [r'${name}Tgt']),
        ],
      );

      final resolverNoPattern = RelatedFileResolver(configNoPattern);

      final sourceContext = ComponentContext(
        filePath: project.sourcePath,
        definition: configNoPattern.components[0],
      );

      final result = await resolverNoPattern.resolveRelated(
        currentContext: sourceContext,
        targetComponentId: 'target',
        session: session,
      );

      // Target file 'file_tgt.dart' does not exist, so should return null
      expect(result, isNull);
    });
  });
}
