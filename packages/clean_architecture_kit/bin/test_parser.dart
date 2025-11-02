import 'dart:io';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:yaml/yaml.dart';

/// A utility to recursively convert nested Yaml structures into standard Dart collections.
dynamic _convertNode(dynamic node) {
  if (node is YamlMap) {
    return Map<String, dynamic>.from(
        node.map((key, value) => MapEntry(key.toString(), _convertNode(value))));
  }
  if (node is YamlList) {
    return node.map(_convertNode).toList();
  }
  return node;
}

void main() {
  // Path from the kit package to the example's analysis_options
  const path = 'example/analysis_options.yaml';
  final file = File(path);

  if (!file.existsSync()) {
    print('ERROR: Could not find analysis_options.yaml at the expected path: $path');
    return;
  }

  try {
    final content = file.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap;
    final customLintConfig = yaml['custom_lint'] as YamlMap?;
    final rulesList = customLintConfig?['rules'] as YamlList?;

    if (rulesList == null) {
      print('ERROR: Could not find the `rules` list under `custom_lint`.');
      return;
    }

    Map<String, dynamic>? architectureConfigMap;
    for (final rule in rulesList) {
      if (rule is YamlMap && rule.containsKey('clean_architecture')) {
        final dynamic rawValue = rule['clean_architecture'];
        final dynamic convertedValue = _convertNode(rawValue);

        // ▼▼▼ THIS IS THE FIX ▼▼▼
        // We safely check if the converted value is a Map before casting and assigning it.
        if (convertedValue is Map) {
          architectureConfigMap = Map<String, dynamic>.from(convertedValue);
        }
        // ▲▲▲ END OF FIX ▲▲▲

        break; // Stop searching once we've found and processed it.
      }
    }

    if (architectureConfigMap == null) {
      print('ERROR: Iterated through the `rules` list but could not find the `clean_architecture` block.');
      return;
    }

    print('Configuration block found. Attempting to parse...');

    // This is where a crash will happen if a config model has a bug.
    CleanArchitectureConfig.fromMap(architectureConfigMap);

    print('✅ SUCCESS: Configuration parsed without errors!');
    print('This means your config models are correct. The issue is likely a dependency/caching problem.');
    print('Please run `melos clean && melos bootstrap` and restart your IDE\'s analysis server.');

  } catch (e, st) {
    print('❌ FATAL ERROR: The config parser crashed!');
    print('This is the bug that is stopping your lints from working.');
    print('Error: $e');
    print('StackTrace:\n$st');
  }
}