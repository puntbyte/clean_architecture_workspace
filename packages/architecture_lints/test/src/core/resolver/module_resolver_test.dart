import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/definitions/module_definition.dart';
import 'package:architecture_lints/src/engines/file/module_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('ModuleResolver', () {
    // We use the placeholder from ConfigKeys to ensure the test matches the implementation's expectation.
    // Assuming ConfigKeys.placeholder.name is updated to '{{name}}'
    final namePlaceholder = ConfigKeys.placeholder.name;

    final modules = [
      ModuleDefinition(
        key: 'feature',
        path: 'features/$namePlaceholder', // e.g. 'features/{{name}}'
        strict: true,
      ),
      const ModuleDefinition(
        key: 'core',
        path: 'core',
        strict: false,
      ),
      const ModuleDefinition(
        key: 'shared',
        path: 'shared',
        strict: false,
      ),
    ];

    final resolver = ModuleResolver(modules);

    test('should resolve dynamic module instance from path', () {
      const filePath = 'lib/features/auth/domain/usecases/login.dart';
      final result = resolver.resolve(filePath);

      expect(result, isNotNull);
      expect(result?.definition.key, 'feature');
      expect(result?.name, 'auth'); // Extracted {{name}}
    });

    test('should resolve static module', () {
      const filePath = 'lib/core/network/client.dart';
      final result = resolver.resolve(filePath);

      expect(result, isNotNull);
      expect(result?.definition.key, 'core');
      expect(result?.name, 'core'); // Static name
    });

    test('should return null for path outside defined modules', () {
      const filePath = 'lib/main.dart';
      final result = resolver.resolve(filePath);

      expect(result, isNull);
    });

    test('should handle Windows file paths', () {
      // Simulate Windows separators
      const filePath = r'lib\features\payment\data\repo.dart';
      final result = resolver.resolve(filePath);

      expect(result, isNotNull);
      expect(result?.definition.key, 'feature');
      expect(result?.name, 'payment');
    });

    test('should ignore folder names appearing before lib/ (False Positives)', () {
      // e.g., Project is located in a folder named "features"
      // /Users/developer/project_features/lib/main.dart
      const filePath = '/project_features/lib/main.dart';
      final result = resolver.resolve(filePath);

      expect(result, isNull, reason: 'Should not match project root directory name');
    });

    test('should resolve module correctly when nested deep in lib', () {
      // Example: lib/src/features/settings/...
      const filePath = 'lib/src/features/settings/page.dart';
      final result = resolver.resolve(filePath);

      expect(result, isNotNull);
      expect(result?.name, 'settings');
    });

    test('should distinguish between similar static module names', () {
      final complexModules = [
        const ModuleDefinition(key: 'core_ui', path: 'core_ui'),
        const ModuleDefinition(key: 'core', path: 'core'),
      ];
      final complexResolver = ModuleResolver(complexModules);

      // 1. Exact match for core_ui
      var result = complexResolver.resolve('lib/core_ui/widget.dart');
      expect(result?.definition.key, 'core_ui');

      // 2. Exact match for core (should not be confused by partial match of core_ui)
      result = complexResolver.resolve('lib/core/util.dart');
      expect(result?.definition.key, 'core');
    });
  });
}