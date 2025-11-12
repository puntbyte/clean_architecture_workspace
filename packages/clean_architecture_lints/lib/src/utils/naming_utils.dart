// lib/src/utils/naming_utils.dart
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/extensions/string_extension.dart';

/// A utility class for handling naming conventions and validations.
class NamingUtils {
  const NamingUtils._(); // This class is not meant to be instantiated.

  /// Converts a method name into an expected use case class name based on config.
  static String getExpectedUseCaseClassName(String methodName, CleanArchitectureConfig config) {
    final pascal = methodName.toPascalCase();
    final template = config.naming.useCase.pattern;
    return template.replaceAll('{{name}}', pascal);
  }

  /// Extracts the core name from a class name based on a template.
  /// For example, extracts 'User' from 'UserRepository' using '{{name}}Repository'.
  static String? extractName({required String name, required String template}) {
    // We only care about {{name}} for extraction. Treat {{base}} as a wildcard.
    final pattern = template
        .replaceAll('{{name}}', '([A-Z][a-zA-Z0-9]+)')
        .replaceAll('{{type}}', '[A-Z][a-zA-Z0-9]+');

    final regex = RegExp('^$pattern\$');
    final match = regex.firstMatch(name);

    // Group 1 will be the capture of {{name}}.
    return match?.group(1);
  }

  /// Validates a class name against a configured template string.
  /// This is the definitive, correct, and robust implementation.
  /// Validates a class name against a configured template string.
  static bool validateName({
    required String name,
    required String template,
  }) {
    // Special-case: when template is exactly '{{name}}' we treat it as a single
    // PascalCase identifier but *reject* common architectural suffixes
    // (anti-pattern protection).
    if (template == '{{name}}') {
      final isPascal = RegExp(r'^[A-Z][a-zA-Z0-9]*$').hasMatch(name);
      final hasForbiddenSuffix =
      RegExp(r'(Entity|Model|UseCase|Usecase|Repository|DataSource)$')
          .hasMatch(name);
      return isPascal && !hasForbiddenSuffix;
    }

    // Build a safe regex pattern from the template by iterating and replacing
    // placeholders while escaping literal characters.
    const namePlaceholder = '{{name}}';
    const typePlaceholder = '{{type}}';
    const bothPlaceholder = '{{type}}{{name}}';

    // Updated token definitions to allow single-letter Pascal tokens:
    // - a Pascal token is an uppercase letter followed by zero or more alnum chars.
    // - when two placeholders are adjacent, the first should be non-greedy so
    //   partitioning works correctly.
    const pascalToken = '([A-Z][a-zA-Z0-9]*)';
    const pascalTokenNonGreedy = '([A-Z][a-zA-Z0-9]*?)';

    final buffer = StringBuffer();
    for (var i = 0; i < template.length;) {
      // check for {{type}}{{name}} first
      if (i <= template.length - bothPlaceholder.length &&
          template.substring(i, i + bothPlaceholder.length) == bothPlaceholder) {
        // non-greedy first token, greedy second token
        buffer.write('$pascalTokenNonGreedy$pascalToken');
        i += bothPlaceholder.length;
        continue;
      }

      // check for single placeholders
      if (i <= template.length - namePlaceholder.length &&
          template.substring(i, i + namePlaceholder.length) == namePlaceholder) {
        buffer.write(pascalToken);
        i += namePlaceholder.length;
        continue;
      }

      if (i <= template.length - typePlaceholder.length &&
          template.substring(i, i + typePlaceholder.length) == typePlaceholder) {
        buffer.write(pascalToken);
        i += typePlaceholder.length;
        continue;
      }

      // literal character -> escape for regex safety
      buffer.write(RegExp.escape(template[i]));
      i++;
    }

    final pattern = '^$buffer\$';
    final regex = RegExp(pattern);
    return regex.hasMatch(name);
  }
}
