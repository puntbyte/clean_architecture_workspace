// test/src/models/inheritances_config_test.dart

import 'package:clean_architecture_lints/src/models/configs/inheritances_config.dart';
import 'package:clean_architecture_lints/src/models/configs/type_config.dart';
import 'package:test/test.dart';

void main() {
  // Mock TypesConfig
  final typesMap = {
    'type_definitions': {
      'usecase': [
        {'key': 'base', 'name': 'BaseUseCase', 'import': 'pkg:base.dart'},
        {'key': 'unary', 'name': 'UnaryUseCase'}, // Inherits pkg:base.dart
      ],
      'failure': [
        {'key': 'server', 'name': 'ServerFailure', 'import': 'pkg:fail.dart'}
      ]
    }
  };
  final typeDefs = TypesConfig.fromMap(typesMap);

  group('InheritanceDetail', () {
    group('fromMapWithExpansion', () {
      test('should resolve details from "type" key', () {
        final map = {'type': 'usecase.unary'};

        final details = InheritanceDetail.fromMapWithExpansion(map, typeDefs);

        expect(details, hasLength(1));
        expect(details.first.name, 'UnaryUseCase');
        expect(details.first.import, 'pkg:base.dart'); // Inherited import
      });

      test('should resolve details from list of "type" keys', () {
        final map = {
          'type': ['usecase.base', 'failure.server']
        };

        final details = InheritanceDetail.fromMapWithExpansion(map, typeDefs);

        expect(details, hasLength(2));

        expect(details[0].name, 'BaseUseCase');
        expect(details[0].import, 'pkg:base.dart');

        expect(details[1].name, 'ServerFailure');
        expect(details[1].import, 'pkg:fail.dart');
      });

      test('should ignore unknown type keys', () {
        final map = {'type': 'unknown.key'};
        final details = InheritanceDetail.fromMapWithExpansion(map, typeDefs);
        expect(details, isEmpty);
      });

      test('should fallback to standard parsing if "type" is missing', () {
        final map = {'name': 'Manual', 'import': 'pkg:manual'};
        final details = InheritanceDetail.fromMapWithExpansion(map, typeDefs);

        expect(details, hasLength(1));
        expect(details.first.name, 'Manual');
      });
    });
  });

  group('InheritancesConfig', () {
    test('should parse rules using type definitions', () {
      final map = {
        'inheritances': [
          {
            'on': 'usecase',
            'required': {'type': 'usecase.unary'}
          }
        ]
      };

      final config = InheritancesConfig.fromMap(map, typeDefs);

      expect(config.rules, hasLength(1));
      expect(config.rules.first.required, hasLength(1));
      expect(config.rules.first.required.first.name, 'UnaryUseCase');
    });
  });
}