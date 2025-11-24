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

        test('should resolve port from its domain layer path', () {
          const path = '/project/lib/features/auth/domain/ports/auth_port.dart';
          expect(resolver.getComponent(path), ArchComponent.port);
        });

        test('should resolve repository implementation from its data layer path', () {
          const path = '/project/lib/features/auth/data/repositories/auth_repo_impl.dart';
          expect(resolver.getComponent(path), ArchComponent.repository);
        });

        test('should resolve source parent from its data layer path', () {
          const path = '/project/lib/features/auth/data/sources/auth_source.dart';
          expect(resolver.getComponent(path), ArchComponent.source);
        });

        test('should return unknown for files not in an architectural layer', () {
          const path = '/project/lib/core/utils/types.dart';
          expect(resolver.getComponent(path), ArchComponent.unknown);
        });
      });
    });

    group('getComponent with refinement from class name', () {
      late LayerResolver resolver;
      const managerPath = '/project/lib/features/auth/presentation/managers/auth_bloc.dart';
      const sourcePath = '/project/lib/features/auth/data/sources/auth_source.dart';

      setUp(() => resolver = LayerResolver(makeConfig()));

      test('should refine manager path to EventInterface for a name ending in Event', () {
        final component = resolver.getComponent(managerPath, className: 'AuthEvent');
        expect(component, ArchComponent.eventInterface);
      });

      test('should refine manager path to StateImplementation for a state implementation name', () {
        final component = resolver.getComponent(managerPath, className: 'AuthLoading');
        expect(component, ArchComponent.stateImplementation);
      });

      test('should refine manager path to Manager for a name ending in Bloc', () {
        final component = resolver.getComponent(managerPath, className: 'AuthBloc');
        expect(component, ArchComponent.manager);
      });

      test('should refine source path to SourceImplementation for an implementation name', () {
        final component = resolver.getComponent(sourcePath, className: 'DefaultAuthDataSource');
        expect(component, ArchComponent.sourceImplementation);
      });

      test('should refine source path to SourceInterface for an interface name', () {
        final component = resolver.getComponent(sourcePath, className: 'AuthDataSource');
        expect(component, ArchComponent.sourceInterface);
      });
    });
  });
}
