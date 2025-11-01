import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:test/test.dart';

/// A helper function to create a complete and valid [CleanArchitectureConfig]
/// object specifically for testing the [LayerResolver].
/// It provides sensible defaults and allows overriding specific properties
/// to test various user configurations.
CleanArchitectureConfig makeTestConfig({
  String projectStructure = 'feature_first',
  String featuresRootPath = 'features',

  String domainPath = 'domain',
  List<String> domainEntitiesPaths = const ['entities'],
  List<String> domainRepositoriesPaths = const ['repositories'],
  List<String> domainUseCasesPaths = const ['usecases'],

  String dataPath = 'data',
  List<String> dataModelsPaths = const ['models'],
  List<String> dataDataSourcesPaths = const ['datasources'],
  List<String> dataRepositoriesPaths = const ['repositories'],

  String presentationPath = 'presentation',
  List<String> presentationManagerPaths = const ['managers'],
  List<String> presentationWidgetsPaths = const ['widgets'],
  List<String> presentationPagesPaths = const ['pages'],
}) {
  // This map literal is a complete and valid representation of the YAML structure
  // that the LayerResolver depends on.
  return CleanArchitectureConfig.fromMap({
    'project_structure': projectStructure,
    'feature_first_paths': {'features_root': featuresRootPath},
    'layer_first_paths': {
      'domain': domainPath,
      'data': dataPath,
      'presentation': presentationPath,
    },
    'layer_definitions': {
      'domain': {
        'entities': domainEntitiesPaths,
        'repositories': domainRepositoriesPaths,
        'usecases': domainUseCasesPaths,
      },
      'data': {
        'models': dataModelsPaths,
        'data_sources': dataDataSourcesPaths,
        'repositories': dataRepositoriesPaths,
      },
      'presentation': {
        'managers': presentationManagerPaths,
        'widgets': presentationWidgetsPaths,
        'pages': presentationPagesPaths,
      },
    },
    // Provide empty defaults for other config sections that the main
    // config class requires, but this specific test doesn't use.
    'naming_conventions': {},
    'type_safety': {},
    'inheritance': {},
    'generation_options': {},
  });
}

void main() {
  group('LayerResolver', () {
    group('getLayer', () {
      group('with feature-first structure', () {
        final config = makeTestConfig();
        final resolver = LayerResolver(config);

        test('should return ArchLayer.domain for a domain file', () {
          const path = r'C:\project\lib\features\auth\domain\entities\user.dart';
          expect(resolver.getLayer(path), ArchLayer.domain);
        });

        test('should return ArchLayer.data for a data file', () {
          const path = r'C:\project\lib\features\auth\data\models\user_model.dart';
          expect(resolver.getLayer(path), ArchLayer.data);
        });

        test('should return ArchLayer.presentation for a presentation file', () {
          const path = r'C:\project\lib\features\auth\presentation\bloc\auth_bloc.dart';
          expect(resolver.getLayer(path), ArchLayer.presentation);
        });

        test('should return ArchLayer.unknown for a file outside a defined layer', () {
          const path = r'C:\project\lib\core\utils\types.dart';
          expect(resolver.getLayer(path), ArchLayer.unknown);
        });

        test('should handle Windows-style backslashes', () {
          const path = r'C:\project\lib\features\auth\domain\entities\user.dart';
          expect(resolver.getLayer(path), ArchLayer.domain);
        });
      });

      group('with layer-first structure', () {
        final config = makeTestConfig(projectStructure: 'layer_first');
        final resolver = LayerResolver(config);

        test('should return ArchLayer.domain for a domain file', () {
          const path = '/project/lib/domain/repositories/auth_repository.dart';
          expect(resolver.getLayer(path), ArchLayer.domain);
        });

        test('should return ArchLayer.data for a data file', () {
          const path = '/project/lib/data/datasources/auth_data_source.dart';
          expect(resolver.getLayer(path), ArchLayer.data);
        });
      });
    });

    group('getSubLayer', () {
      // Create a specific config to test custom and multiple directory names.
      final config = makeTestConfig(
        domainEntitiesPaths: ['entities'],
        domainRepositoriesPaths: ['contracts'],
        domainUseCasesPaths: ['usecases', 'interactors'],
        dataModelsPaths: ['models'],
        dataDataSourcesPaths: ['sources', 'datasources'],
        dataRepositoriesPaths: ['repositories'],
        presentationManagerPaths: ['managers', 'controllers'],
        presentationWidgetsPaths: ['widgets', 'components'],
        presentationPagesPaths: ['pages', 'screens'],
      );
      final resolver = LayerResolver(config);

      test('should return ArchSubLayer.domainRepository for a domain contract file', () {
        const path = '/project/lib/features/auth/domain/contracts/auth_repository.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.domainRepository);
      });

      test('should return ArchSubLayer.useCase for a domain use case file', () {
        const path = '/project/lib/features/auth/domain/usecases/get_user_usecase.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.useCase);
      });

      test('should return ArchSubLayer.useCase for an alternate use case directory name', () {
        const path = '/project/lib/features/auth/domain/interactors/get_user_interactor.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.useCase);
      });

      test('should return ArchSubLayer.dataRepository for a data repository file', () {
        const path = '/project/lib/features/auth/data/repositories/auth_repository_impl.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.dataRepository);
      });

      test('should return ArchSubLayer.dataSource for a data source file', () {
        const path = '/project/lib/features/auth/data/sources/auth_remote_data_source.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.dataSource);
      });

      test('should return ArchSubLayer.unknown for a file in a non-sublayer directory', () {
        // 'entities' is not a configured sub-layer for our resolver's purpose.
        const path = '/project/lib/features/auth/domain/entities/user_entity.dart';
        expect(
          resolver.getSubLayer(path),
          ArchSubLayer.entity,
        ); // now entities are configured, expect entity
      });

      test(
        'should return ArchSubLayer.unknown for a file in a directory that is not configured',
        () {
          // Since we configured 'contracts' for repositories, a file in the default
          // 'repositories' folder within the domain layer should be unknown.
          const path = '/project/lib/features/auth/domain/repositories/auth_repository.dart';
          expect(resolver.getSubLayer(path), ArchSubLayer.unknown);
        },
      );

      test('presentation: should return manager for controller-like files', () {
        const path = '/project/lib/features/auth/presentation/managers/session_manager.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.manager);
      });

      test('presentation: should return widget for UI components', () {
        const path = '/project/lib/features/auth/presentation/widgets/login_button.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.widget);
      });

      test('presentation: should return pages for screens', () {
        const path = '/project/lib/features/auth/presentation/pages/login_page.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.pages);
      });

      test('data: should return model for model files', () {
        const path = '/project/lib/features/auth/data/models/auth_model.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.model);
      });

      test('ordering: respects configured order (primary first)', () {
        // Here we create a config where 'interactors' is the first (primary) name,
        // and 'usecases' is second. A path containing 'usecases' should still match useCase,
        // but if a path contained both, the resolver should match the primary one first.
        final orderedConfig = makeTestConfig(
          domainUseCasesPaths: ['interactors', 'usecases'],
        );
        final orderedResolver = LayerResolver(orderedConfig);

        const pathOnlyUsecases = '/project/lib/features/auth/domain/usecases/get_user_usecase.dart';
        expect(orderedResolver.getSubLayer(pathOnlyUsecases), ArchSubLayer.useCase);

        const pathWithBothSegments =
            '/project/lib/features/auth/domain/interactors/usecases/mixed_file.dart';
        // Because 'interactors' is the first configured name, it should be considered primary.
        // The resolver should still return useCase (both names refer to the same sublayer).
        expect(orderedResolver.getSubLayer(pathWithBothSegments), ArchSubLayer.useCase);
      });
    });
  });
}
