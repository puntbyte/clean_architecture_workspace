// lib/src/engines/generator/code_generator.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/engines/template/template.dart';
import 'package:architecture_lints/src/engines/variable/variable.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/action_definition.dart';
import 'package:dart_style/dart_style.dart';

class CodeGenerator {
  final ArchitectureConfig config;
  final TemplateLoader templateLoader;
  final MustacheRenderer _renderer;
  final String packageName;

  CodeGenerator(
    this.config,
    this.templateLoader,
    this.packageName,
  ) : _renderer = const MustacheRenderer();

  /// Generates code based on the [action] configuration.
  /// NOW SYNCHRONOUS.
  String? generate({
    required ActionDefinition action,
    required AstNode sourceNode,
  }) {
    // 1. Resolve Template Definition
    final templateDef = config.templates[action.templateId];
    if (templateDef == null) return null;

    // 2. Load Template Content (Sync)
    String templateString;
    try {
      templateString = templateLoader.loadContent(templateDef);
    } catch (e) {
      return null;
    }

    if (templateString.isEmpty) return null;

    // 3. Build Variable Context
    final resolver = VariableResolver(
      sourceNode: sourceNode,
      config: config,
      packageName: packageName,
    );

    final context = resolver.resolveMap(action.variables);

    // 4. Render Template
    final codeBody = _renderer.render(templateString, context);

    // 5. Prepend Debug Header if requested
    final full = action.debug ? '${_generateDebugHeader(context)}\n$codeBody' : codeBody;

    // 6. Optionally format using dart_style
    if (action.format) {
      try {
        final formatter = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
          pageWidth: action.formatLineLength ?? 80,
        );
        // Format entire output (debug header is comments so OK).
        return formatter.format(full);
      } catch (e) {
        // If formatting fails, return the unformatted code with a format-error comment.
        return '/* Format error: $e */\n$full';
      }
    }

    return full;
  }

  String _generateDebugHeader(Map<String, dynamic> context) {
    final buffer = StringBuffer()
      ..writeln('// ==========================================')
      ..writeln('// [DEBUG] GENERATION CONTEXT')
      ..writeln('// ==========================================');

    _writeMap(buffer, context, '');

    buffer.writeln('// ==========================================\n');
    return buffer.toString();
  }

  void _writeMap(StringBuffer buffer, Map<String, dynamic> map, String indent) {
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        buffer.writeln('// $indent$key: {');
        _writeMap(buffer, value, '$indent  ');
        buffer.writeln('// $indent}');
      } else if (value is Iterable) {
        final listStr = value.map((e) => e.toString()).join(', ');
        final display = listStr.length > 100 ? '${listStr.substring(0, 97)}...' : listStr;
        buffer.writeln('// $indent$key: [$display] (Length: ${value.length})');
      } else {
        buffer.writeln('// $indent$key: "$value"');
      }
    });
  }

  void _writeMapShort(StringBuffer buffer, Map<String, dynamic> map, String indent) {
    map.forEach((key, value) {
      // Don't expand source unless asked, it's huge
      if (key == 'source' && indent.isEmpty) {
        buffer.writeln('// $key: <SourceWrapper>');
        return;
      }

      if (value is Map<String, dynamic>) {
        buffer.writeln('// $indent$key: {');
        _writeMap(buffer, value, '$indent  ');
        buffer.writeln('// $indent}');
      } else if (value is Iterable) {
        // Just print length to keep it clean
        buffer.writeln('// $indent$key: [List, length: ${value.length}]');
      } else {
        buffer.writeln('// $indent$key: "$value"');
      }
    });
  }
}

/*
void _writeMapOld(StringBuffer buffer, Map<String, dynamic> map, String indent) {
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        buffer.writeln('// $indent$key: {');
        _writeMap(buffer, value, '$indent  ');
        buffer.writeln('// $indent}');
      } else if (value is Iterable) {
        final listStr = value.map((e) => e.toString()).join(', ');
        final display = listStr.length > 100 ? '${listStr.substring(0, 97)}...' : listStr;
        buffer.writeln('// $indent$key: [$display] (Length: ${value.length})');
      } else {
        buffer.writeln('// $indent$key: "$value"');
      }
    });
  }


 */
