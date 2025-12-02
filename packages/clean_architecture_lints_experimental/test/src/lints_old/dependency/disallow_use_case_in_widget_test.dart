// test/src/lints/dependency/disallow_use_case_in_widget_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/dependency/disallow_use_case_in_widget.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowUseCaseInWidget Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('usecase_in_widget_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // 1. Define a UseCase in Domain
      addFile(
        'lib/features/user/domain/usecases/get_user.dart',
        'class GetUser {}',
      );

      // 2. Define a Manager (Bloc) in Presentation (Allowed dependency)
      addFile(
        'lib/features/user/presentation/managers/user_bloc.dart',
        'class UserBloc {}',
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
      final lint = DisallowUseCaseInWidget(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when a Widget has a UseCase field', () async {
      final path = 'lib/features/user/presentation/widgets/user_card.dart';
      addFile(path, '''
        import '../../domain/usecases/get_user.dart';
        
        class UserCard {
          final GetUser getUser; // VIOLATION
          UserCard(this.getUser);
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Widgets must not depend on or invoke UseCases'));
    });

    test('reports violation when a Widget instantiates a UseCase locally', () async {
      final path = 'lib/features/user/presentation/widgets/login_button.dart';
      addFile(path, '''
        import '../../domain/usecases/get_user.dart';
        
        class LoginButton {
          void onPressed() {
            final useCase = GetUser(); // VIOLATION
            print(useCase);
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('does NOT report violation when depending on a Manager/Bloc', () async {
      final path = 'lib/features/user/presentation/widgets/user_screen.dart';
      addFile(path, '''
        import '../managers/user_bloc.dart';
        
        class UserScreen {
          final UserBloc bloc; // OK
          UserScreen(this.bloc);
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('does NOT report violation when file is NOT a widget', () async {
      // A Bloc/Manager (Presentation) depending on a UseCase is perfectly fine.
      // The lint should skip this file because it's not in the 'widgets' directory.
      final path = 'lib/features/user/presentation/managers/user_controller.dart';
      addFile(path, '''
        import '../../domain/usecases/get_user.dart';
        
        class UserController {
          final GetUser useCase; // OK (It's a manager, not a widget)
          UserController(this.useCase);
        }
      ''');

      final lints = await runLint(path);
      expect(
        lints,
        isEmpty,
        reason: 'Lint should only check files identified as Widgets.',
      );
    });
  });
}