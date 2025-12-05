import 'package:mustache_template/mustache.dart';
import 'package:recase/recase.dart';

class TemplateEngine {
  const TemplateEngine._();

  /// Renders a [template] string using the [coreName].
  ///
  /// Variables available in template:
  /// - {{name.pascal}} -> UserProfile
  /// - {{name.camel}}  -> userProfile
  /// - {{name.snake}}  -> user_profile
  /// - {{name.param}}  -> user-profile
  static String render(String template, String coreName) {
    final rc = ReCase(coreName);

    // Prepare the context for Mustache
    // We support both {{name.pascal}} (nested) and legacy styles if needed
    final values = {
      'name': {
        'original': coreName,
        'pascal': rc.pascalCase,
        'camel': rc.camelCase,
        'snake': rc.snakeCase,
        'constant': rc.constantCase,
        'param': rc.paramCase,
        'dot': rc.dotCase,
        'path': rc.pathCase,
      },
    };

    // 'lenient: true' prevents crashing on missing tags
    return Template(template, lenient: true).renderString(values);
  }
}
