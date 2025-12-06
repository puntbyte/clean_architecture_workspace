import 'dart:io';

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/parsing/config_loader.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ConfigLoader', () {
    late Directory tempDir;

    setUp(() {
      // 1. Create a fresh temporary directory for every test
      // e.g., /tmp/arch_lint_test_A1B2C3
      tempDir = Directory.systemTemp.createTempSync('arch_lint_test_');

      // 2. Clear the singleton cache so previous tests don't affect this one
      ConfigLoader.resetCache();
    });

    tearDown(() {
      // 3. Cleanup: Delete the temp directory and all files inside it
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should return null if config file does not exist anywhere in tree', () async {
      // Create a dummy dart file: /tmp/.../lib/main.dart
      final sourceFile = p.join(tempDir.path, 'lib', 'main.dart');
      File(sourceFile).createSync(recursive: true);

      final config = await ConfigLoader.loadFromContext(sourceFile);

      expect(config, isNull);
    });

    test('should load config when located in the same directory', () async {
      // /tmp/.../architecture.yaml
      final configPath = p.join(tempDir.path, ConfigKeys.configFilename);
      File(configPath).writeAsStringSync('''
components:
  domain:
    path: domain
      ''');

      // /tmp/.../main.dart
      final sourceFile = p.join(tempDir.path, 'main.dart');
      File(sourceFile).createSync();

      final config = await ConfigLoader.loadFromContext(sourceFile);

      expect(config, isNotNull);
      expect(config!.components.first.id, 'domain');
    });

    test('should walk up parent directories to find config', () async {
      // Root: /tmp/.../architecture.yaml
      final configPath = p.join(tempDir.path, ConfigKeys.configFilename);
      File(configPath).writeAsStringSync('components: { core: { path: core } }');

      // Deep file: /tmp/.../lib/features/auth/presentation/request_login.dart
      final deepFile = p.join(tempDir.path, 'lib', 'features', 'auth', 'presentation', 'request_login.dart');
      File(deepFile).createSync(recursive: true);

      final config = await ConfigLoader.loadFromContext(deepFile);

      expect(config, isNotNull);
      expect(config!.components.first.id, 'core');
    });

    test('should return null if YAML is malformed', () async {
      final configPath = p.join(tempDir.path, ConfigKeys.configFilename);
      // Invalid YAML (tab indentation is illegal in JSON-superset YAML, or just garbage text)
      File(configPath).writeAsStringSync('components: [ unclosed_list]');

      final sourceFile = p.join(tempDir.path, 'main.dart');
      File(sourceFile).createSync();

      // Should handle the exception internally and return null
      final config = await ConfigLoader.loadFromContext(sourceFile);

      expect(config, isNull);
    });

    test('should cache the configuration for the same root', () async {
      final configPath = p.join(tempDir.path, ConfigKeys.configFilename);
      File(configPath).writeAsStringSync('components: { a: { path: a } }');

      final sourceFile = p.join(tempDir.path, 'main.dart');
      File(sourceFile).createSync();

      // First Load
      await ConfigLoader.loadFromContext(sourceFile);

      // Modify the file on disk
      File(configPath).writeAsStringSync('components: { b: { path: b } }');

      // Second Load (Should return cached version 'a', ignoring disk change 'b')
      final config2 = await ConfigLoader.loadFromContext(sourceFile);

      expect(config2!.components.first.id, 'a');
    });
  });
}