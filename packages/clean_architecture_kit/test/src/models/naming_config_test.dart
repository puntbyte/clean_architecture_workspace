// test/src/models/naming_config_test.dart

import 'package:clean_architecture_kit/src/models/naming_config.dart';
import 'package:test/test.dart';

void main() {
  group('NamingConfig', () {
    group('fromMap factory', () {
      test('should parse a map with simple string values', () {
        final map = {
          'entity': '{{name}}Data',
          'model': '{{name}}TransferObject',
        };
        final config = NamingConfig.fromMap(map);

        expect(config.entity.pattern, '{{name}}Data');
        expect(config.entity.antipatterns, isEmpty);
        expect(config.model.pattern, '{{name}}TransferObject');
        expect(config.useCase.pattern, '{{name}}'); // Default
      });

      test('should parse a map with complex pattern/anti_pattern values', () {
        final map = {
          'entity': {
            'pattern': '{{name}}',
            'anti_pattern': ['{{name}}Entity'],
          },
          'use_case': {
            'pattern': '{{name}}Action',
            'anti_pattern': ['{{name}}UseCase'],
          }
        };
        final config = NamingConfig.fromMap(map);

        expect(config.entity.pattern, '{{name}}');
        expect(config.entity.antipatterns, ['{{name}}Entity']);
        expect(config.useCase.pattern, '{{name}}Action');
        expect(config.useCase.antipatterns, ['{{name}}UseCase']);
      });

      test('should use all default values when map is empty', () {
        final map = <String, dynamic>{};
        final config = NamingConfig.fromMap(map);

        expect(config.entity.pattern, '{{name}}');
        expect(config.model.pattern, '{{name}}Model');
        expect(config.useCase.pattern, '{{name}}');
        expect(config.repository.pattern, '{{name}}Repository');
        expect(config.entity.antipatterns, isEmpty);
      });
    });
  });
}
