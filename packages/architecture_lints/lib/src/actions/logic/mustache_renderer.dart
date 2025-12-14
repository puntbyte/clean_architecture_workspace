// lib/src/actions/logic/mustache_renderer.dart

import 'package:mustache_template/mustache_template.dart';

class MustacheRenderer {
  const MustacheRenderer();

  String render(String templateString, Map<String, dynamic> context) {
    try {
      final template = Template(
        templateString,
        lenient: true,
        htmlEscapeValues: false,
      );

      return template.renderString(context);
    } catch (e) {
      return '/* Error rendering template: $e */';
    }
  }
}
