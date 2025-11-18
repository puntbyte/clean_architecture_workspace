// test/src/analysis/layer_resolver_test.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('LayerResolver', () {
    group('getComponent from path only', () {
      group('when in a feature-first project', () {
        late LayerResolver resolver;
        setUp(() => resolver = LayerResolver(makeConfig(type: 'feature_first')));

        // Domain Layer
        test('should resolve contract from its domain layer path', () {
          const path = '/project/lib/features/auth/domain/contracts/auth_repository.dart';
          expect(resolver.getComponent(path), ArchComponent.contract);
        });

        test('should resolve entity from its domain layer path', () {
          const path = '/project/lib/features/auth/domain/entities/user.dart';
          expect(resolver.getComponent(path), ArchComponent.entity);
        });

        // Data Layer
        test('should resolve model from its data layer path', () {
          const path = '/project/lib/features/auth/data/models/user_model.dart';
          expect(resolver.getComponent(path), ArchComponent.model);
        });

        test('should resolve repository from its data layer path', () {
          const path = '/project/lib/features/auth/data/repositories/auth_repo_impl.dart';
          expect(resolver.getComponent(path), ArchComponent.repository);
        });

        // Presentation Layer
        test('should resolve page from its presentation layer path', () {
          const path = '/project/lib/features/auth/presentation/pages/login_page.dart';
          expect(resolver.getComponent(path), ArchComponent.page);
        });

        test('should resolve manager from its presentation layer path', () {
          const path = '/project/lib/features/auth/presentation/managers/auth_bloc.dart';
          expect(resolver.getComponent(path), ArchComponent.manager);
        });

        // Non-Architectural Paths
        test('should return unknown for files inside a non-architectural core folder', () {
          const path = '/project/lib/core/utils/types.dart';
          expect(resolver.getComponent(path), ArchComponent.unknown);
        });

        test('should return unknown for files directly under the lib folder', () {
          const path = '/project/lib/main.dart';
          expect(resolver.getComponent(path), ArchComponent.unknown);
        });

        test('should return unknown for files outside the lib folder', () {
          const path = '/project/test/features/auth/domain/contracts_test.dart';
          expect(resolver.getComponent(path), ArchComponent.unknown);
        });
      });

      group('when in a layer-first project', () {
        test('should resolve component using a custom directory name', () {
          final config = makeConfig(type: 'layer_first', sourceDir: 'data_sources');
          final resolver = LayerResolver(config);
          const path = '/project/lib/data/data_sources/remote_source.dart';
          expect(resolver.getComponent(path), ArchComponent.source);
        });
      });
    });

    group('getComponent with refinement from class name', () {
      late LayerResolver resolver;
      const managerPath = '/project/lib/features/auth/presentation/managers/auth_bloc.dart';
      const sourcePath = '/project/lib/features/auth/data/sources/auth_source.dart';

      setUp(() => resolver = LayerResolver(makeConfig()));

      // Manager Refinement Tests
      test('should refine manager path to Event when class name ends with Event', () {
        final component = resolver.getComponent(managerPath, className: 'AuthEvent');
        expect(component, ArchComponent.event);
      });

      test('should refine manager path to State when class name ends with State', () {
        final component = resolver.getComponent(managerPath, className: 'AuthState');
        expect(component, ArchComponent.state);
      });

      test('should refine manager path to Manager when class name ends with Bloc', () {
        final component = resolver.getComponent(managerPath, className: 'AuthBloc');
        expect(component, ArchComponent.manager);
      });

      test('should refine manager path to StateImplementation for a generic name', () {
        final component = resolver.getComponent(managerPath, className: 'AuthLoading');
        expect(component, ArchComponent.stateImplementation);
      });

      // Source Refinement Tests
      test(
        'should refine source path to SourceImplementation for a default implementation name',
        () {
          final component = resolver.getComponent(sourcePath, className: 'DefaultAuthDataSource');
          expect(component, ArchComponent.sourceImplementation);
        },
      );

      test('should default to Source for a standard interface name', () {
        final component = resolver.getComponent(sourcePath, className: 'AuthDataSource');
        expect(component, ArchComponent.source);
      });
    });

    // --- NEW TESTS FOR ArchComponent ENUM ---
    group('ArchComponent enum', () {
      group('fromId factory', () {
        test('should return the correct component when id exists', () {
          expect(ArchComponent.fromId('entity'), ArchComponent.entity);
          expect(ArchComponent.fromId('repository.implementation'), ArchComponent.repository);
          expect(ArchComponent.fromId('event.interface'), ArchComponent.event);
        });

        test('should return ArchComponent.unknown when id does not exist', () {
          expect(ArchComponent.fromId('non_existent_id'), ArchComponent.unknown);
          expect(ArchComponent.fromId(''), ArchComponent.unknown);
        });
      });

      group('layer getters', () {
        test('domainLayer should contain all domain-related components', () {
          expect(
            ArchComponent.domainLayer,
            containsAll({ArchComponent.entity, ArchComponent.contract, ArchComponent.usecase}),
          );
          expect(ArchComponent.domainLayer, hasLength(3));
        });

        test('dataLayer should contain all data-related components', () {
          expect(
            ArchComponent.dataLayer,
            containsAll({
              ArchComponent.model,
              ArchComponent.repository,
              ArchComponent.source,
              ArchComponent.sourceImplementation,
            }),
          );
          expect(ArchComponent.dataLayer, hasLength(4));
        });

        test('presentationLayer should contain all presentation-related components', () {
          expect(
            ArchComponent.presentationLayer,
            containsAll({
              ArchComponent.page,
              ArchComponent.widget,
              ArchComponent.manager,
              ArchComponent.event,
              ArchComponent.eventImplementation,
              ArchComponent.state,
              ArchComponent.stateImplementation,
            }),
          );
          expect(ArchComponent.presentationLayer, hasLength(7));
        });
      });
    });
  });
}
