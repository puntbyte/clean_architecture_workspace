// test/src/lints/dependency/disallow_repository_in_presentation_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/dependency/disallow_repository_in_presentation.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowRepositoryInPresentation Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('repo_in_presentation_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // 1. Define a Repository Interface (Port) in Domain
      addFile(
        'lib/features/user/domain/ports/user_repository.dart',
        'abstract class UserRepository {}',
      );

      // 2. Define a UseCase in Domain (Correct alternative)
      addFile(
        'lib/features/user/domain/usecases/get_user.dart',
        'class GetUser {}',
      );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore Windows file lock errors
      }
    });

    Future<List<Diagnostic>> runLint(String filePath) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig();
      final lint = DisallowRepositoryInPresentation(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when a Bloc constructor injects a Repository', () async {
      final path = 'lib/features/user/presentation/managers/user_bloc.dart';
      addFile(path, '''
        import '../../domain/ports/user_repository.dart';
        
        class UserBloc {
          final UserRepository repo; // VIOLATION
          UserBloc(this.repo);
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Do not depend directly on a Repository'));
    });

    test('reports violation when a Widget defines a Repository field', () async {
      final path = 'lib/features/user/presentation/widgets/user_list.dart';
      addFile(path, '''
        import '../../domain/ports/user_repository.dart';
        
        class UserList {
          late final UserRepository repo; // VIOLATION
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('reports violation when a method uses a Repository locally', () async {
      final path = 'lib/features/user/presentation/managers/user_controller.dart';
      addFile(path, '''
        import '../../domain/ports/user_repository.dart';
        
        class UserController {
          void init() {
            UserRepository? repo; // VIOLATION
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('does NOT report violation when depending on a UseCase', () async {
      final path = 'lib/features/user/presentation/managers/user_bloc.dart';
      addFile(path, '''
        import '../../domain/usecases/get_user.dart';
        
        class UserBloc {
          final GetUser getUser; // OK
          UserBloc(this.getUser);
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('does NOT report violation when file is NOT in presentation layer', () async {
      // A Usecase (Domain) depending on a Repository is perfectly fine.
      final path = 'lib/features/user/domain/usecases/update_user.dart';
      addFile(path, '''
        import '../ports/user_repository.dart';
        
        class UpdateUser {
          final UserRepository repo; // OK (Domain layer)
          UpdateUser(this.repo);
        }
      ''');

      final lints = await runLint(path);
      expect(
        lints,
        isEmpty,
        reason: 'Lint should only check the Presentation layer.',
      );
    });
  });
}