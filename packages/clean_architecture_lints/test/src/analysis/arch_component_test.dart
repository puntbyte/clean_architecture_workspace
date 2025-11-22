// test/src/analysis/arch_component_test.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:test/test.dart';

void main() {
  group('ArchComponent', () {
    group('fromId factory', () {
      test('should return correct component when id is valid', () {
        expect(ArchComponent.fromId('entity'), ArchComponent.entity);
        expect(ArchComponent.fromId('port'), ArchComponent.port);
        expect(ArchComponent.fromId('repository'), ArchComponent.repository);
      });

      test('should return unknown when id is invalid', () {
        expect(ArchComponent.fromId('bad_id'), ArchComponent.unknown);
      });
    });

    group('children getter', () {
      test('domain should contain entity, port, and usecase', () {
        expect(ArchComponent.domain.children, equals({
          ArchComponent.entity,
          ArchComponent.port,
          ArchComponent.usecase
        }));
      });

      test('leaf components should have empty children', () {
        expect(ArchComponent.entity.children, isEmpty);
      });
    });

    group('layer getter', () {
      test('should return .domain for domain components', () {
        expect(ArchComponent.entity.layer, ArchComponent.domain);
        expect(ArchComponent.usecaseParameter.layer, ArchComponent.domain);
        expect(ArchComponent.domain.layer, ArchComponent.domain);
      });

      test('should return .data for data components', () {
        expect(ArchComponent.model.layer, ArchComponent.data);
        expect(ArchComponent.sourceImplementation.layer, ArchComponent.data);
        expect(ArchComponent.data.layer, ArchComponent.data);
      });

      test('should return .presentation for presentation components', () {
        expect(ArchComponent.widget.layer, ArchComponent.presentation);
        expect(ArchComponent.eventInterface.layer, ArchComponent.presentation);
        expect(ArchComponent.presentation.layer, ArchComponent.presentation);
      });

      test('should return .unknown for unknown component', () {
        expect(ArchComponent.unknown.layer, ArchComponent.unknown);
      });
    });

    group('Static Layer Getters (Backward Compatibility)', () {
      test('layers getter should return top level layers', () {
        expect(ArchComponent.layers, equals({
          ArchComponent.domain,
          ArchComponent.data,
          ArchComponent.presentation
        }));
      });
    });
  });
}
