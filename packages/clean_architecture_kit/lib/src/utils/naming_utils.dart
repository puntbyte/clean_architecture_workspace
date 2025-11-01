// lib/src/utils/naming_utils.dart

import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/string_extension.dart';

/// A utility class for handling naming conventions and validations.
class NamingUtils {
  const NamingUtils._(); // This class is not meant to be instantiated.

  /// Converts a method name into an expected use case class name based on config.
  static String getExpectedUseCaseClassName(String methodName, CleanArchitectureConfig config) {
    final pascal = methodName.toPascalCase();
    final template = config.naming.useCase;
    return template.replaceAll('{{name}}', pascal);
  }

  /// Validates a class name against a configured template or regex.
  static bool validateName({required String name, required String template}) {
    // Escape parentheses for regex but keep {{name}} as a placeholder
    final pattern = template
        .replaceAll('{{name}}', '([A-Z][a-zA-Z0-9]+)')
        .replaceAllMapped(RegExp(r'\((.*?)\)'), (match) => '(?:${match.group(1)})');

    final regex = RegExp('^$pattern\$');
    return regex.hasMatch(name);
  }
}
