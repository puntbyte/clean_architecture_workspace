import 'package:architecture_lints/src/schema/definitions/module_definition.dart';
import 'package:architecture_lints/src/lints/boundaries/logic/module_logic.dart';
import 'package:test/test.dart';

class ModuleLogicTester with ModuleLogic {}

void main() {
  group('ModuleLogic', () {
    final tester = ModuleLogicTester();

    // Setup config with ${name} syntax
    final modules = [
      const ModuleDefinition(key: 'feature', path: r'features/${name}'),
      const ModuleDefinition(key: 'core', path: 'core'),
    ];

    test(r'should resolve dynamic module using ${name}', () {
      final context = tester.resolveModuleContext('lib/features/auth/domain/user.dart', modules);

      expect(context, isNotNull);
      expect(context?.definition.key, 'feature');
      expect(context?.name, 'auth');
    });

    test('should resolve static module', () {
      final context = tester.resolveModuleContext('lib/core/error/failure.dart', modules);

      expect(context, isNotNull);
      expect(context?.definition.key, 'core');
      expect(context?.name, 'core');
    });

    test('should return null for unmatched path', () {
      final context = tester.resolveModuleContext('lib/other/file.dart', modules);

      expect(context, isNull);
    });

    test('should handle Windows separators', () {
      final context = tester.resolveModuleContext(r'lib\features\billing\data\repo.dart', modules);

      expect(context, isNotNull);
      expect(context?.name, 'billing');
    });
  });
}
