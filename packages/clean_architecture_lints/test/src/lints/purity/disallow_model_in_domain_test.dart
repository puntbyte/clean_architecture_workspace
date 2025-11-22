// test/src/lints/purity/disallow_model_in_domain_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/purity/disallow_model_in_domain.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowModelInDomain Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint(String filePath) async {
      final config = makeConfig();
      final lint = DisallowModelInDomain(config: config, layerResolver: LayerResolver(config));

      final resolvedUnit =
          await contextCollection
                  .contextFor(p.normalize(filePath))
                  .currentSession
                  .getResolvedUnit(p.normalize(filePath))
              as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('model_in_domain_test_');
      projectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(projectPath).createSync(recursive: true);

      writeFile(p.join(projectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(projectPath, '.dart_tool', 'package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // 1. Create a Model in the Data layer.
      writeFile(
        p.join(projectPath, 'lib/features/user/data/models/user_model.dart'),
        'class UserModel {}',
      );

      // 2. Create an Entity in the Domain layer (valid dependency).
      writeFile(
        p.join(projectPath, 'lib/features/user/domain/entities/user.dart'),
        'class User {}',
      );

      contextCollection = AnalysisContextCollection(includedPaths: [projectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when an Entity has a Model field', () async {
      final path = p.join(projectPath, 'lib/features/user/domain/entities/profile.dart');
      writeFile(path, '''
        import '../../data/models/user_model.dart';
        class Profile {
          final UserModel user; // VIOLATION
          Profile(this.user);
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'disallow_model_in_domain');
    });

    test('should report violation when a UseCase returns a Model', () async {
      final path = p.join(projectPath, 'lib/features/user/domain/usecases/get_user.dart');
      writeFile(path, '''
        import '../../data/models/user_model.dart';
        class GetUser {
          UserModel call() => UserModel(); // VIOLATION
        }
      ''');

      final lints = await runLint(path);
      // Expect 2 lints: one for return type, one for constructor call (if type is
      // inferred/explicit) addTypeAnnotation catches `UserModel` in `UserModel call()`.
      expect(lints, isNotEmpty);
      expect(lints.first.diagnosticCode.name, 'disallow_model_in_domain');
    });

    test('should report violation when a generic List contains a Model', () async {
      final path = p.join(projectPath, 'lib/features/user/domain/entities/group.dart');
      writeFile(path, '''
        import '../../data/models/user_model.dart';
        class Group {
          final List<UserModel> members; // VIOLATION
          Group(this.members);
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('should NOT report violation when Domain uses an Entity', () async {
      final path = p.join(projectPath, 'lib/features/user/domain/usecases/get_user.dart');
      writeFile(path, '''
        import '../entities/user.dart';
        class GetUser {
          User call() => User(); // OK
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should NOT report violation when a Data layer class uses a Model', () async {
      // This file is in the data layer (repository implementation), so it CAN use models.
      final path = p.join(
        projectPath,
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        import '../models/user_model.dart';
        class UserRepositoryImpl {
          UserModel toModel() => UserModel(); // OK
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });
  });
}
