// lib/src/configuration/component_config.dart

import 'package:architecture_lints/src/configuration/parsing/config_keys.dart';
import 'package:architecture_lints/src/utils/naming_utils.dart';
import 'package:path/path.dart' as p;

class ComponentConfig {
  final String id;
  final String name;
  final String? path;
  final String? pattern;
  final String? antipattern;
  final String? grammar;

  const ComponentConfig({
    required this.id,
    required this.name,
    this.path,
    this.pattern,
    this.antipattern,
    this.grammar,
  });

  bool matchesPath(String relativeFilePath) {
    if (path == null) return false;
    final normalizedConfigPath = p.normalize(path!);
    final normalizedFilePath = p.normalize(relativeFilePath);
    return normalizedFilePath.contains(normalizedConfigPath);
  }

  /// Check if a class name is valid according to 'pattern'
  bool isValidName(String className) {
    if (pattern == null) return true; // No pattern = anything goes
    return NamingUtils.validate(name: className, template: pattern!);
  }

  /// Check if a class name is invalid according to 'antipattern'
  bool isForbiddenName(String className) {
    if (antipattern == null) return false; // No antipattern = safe
    return NamingUtils.validate(name: className, template: antipattern!);
  }
}
