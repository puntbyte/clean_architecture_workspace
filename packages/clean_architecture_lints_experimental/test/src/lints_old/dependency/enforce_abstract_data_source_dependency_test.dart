// test/src/lints/dependency/enforce_abstract_data_source_dependency_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/dependency/enforce_abstract_data_source_dependency.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceAbstractDataSourceDependency Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('abstract_ds_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Define the Source Interface (Allowed)
      // Named '...DataSource' to match default naming conventions for Interfaces
      addFile(
        'lib/features/user/data/sources/user_remote_data_source.dart',
        'abstract class UserRemoteDataSource {}',
      );

      // Define the Source Implementation (Forbidden)
      // Named '...DataSourceImpl' to match default naming conventions for Impls
      addFile(
        'lib/features/user/data/sources/user_remote_data_source_impl.dart',
        '''
        import 'user_remote_data_source.dart';
        class UserRemoteDataSourceImpl implements UserRemoteDataSource {}
        ''',
      );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore Windows file lock errors
      }
    });

    // FIX: Added curly braces to make 'filePath' a named parameter
    Future<List<Diagnostic>> runLint({required String filePath}) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      // IMPORTANT: We must provide naming rules so the LayerResolver knows
      // which file is the Interface and which is the Implementation.
      final config = makeConfig(
        namingRules: [
          {'on': 'source.interface', 'pattern': '{{name}}DataSource'},
          {'on': 'source.implementation', 'pattern': '{{name}}DataSourceImpl'},
        ],
      );

      final lint = EnforceAbstractDataSourceDependency(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when Repository depends on Concrete DataSource', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_data_source_impl.dart';
        
        class UserRepositoryImpl {
          // VIOLATION: Depends on Impl, not Interface
          final UserRemoteDataSourceImpl dataSource; 
          UserRepositoryImpl(this.dataSource);
        }
      ''');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Repositories must depend on DataSource abstractions'));
      // The smart correction should suggest the interface
      expect(lints.first.correctionMessage, contains('Depend on the `UserRemoteDataSource` interface'));
    });

    test('reports violation when Repository uses Concrete DataSource in method body', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_data_source_impl.dart';
        
        class UserRepositoryImpl {
          void doSomething() {
            // VIOLATION: Instantiating concrete class
            final source = UserRemoteDataSourceImpl(); 
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, hasLength(1));
    });

    test('does not report violation when Repository depends on Abstract DataSource', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_data_source.dart';
        
        class UserRepositoryImpl {
          // OK: Depends on Interface
          final UserRemoteDataSource dataSource; 
          UserRepositoryImpl(this.dataSource);
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('ignores files that are not repositories', () async {
      // A DI container or main file might need to instantiate the concrete class.
      final path = 'lib/injection_container.dart';
      addFile(path, '''
        import 'features/user/data/sources/user_remote_data_source_impl.dart';
        void init() {
          final source = UserRemoteDataSourceImpl(); // OK here
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}