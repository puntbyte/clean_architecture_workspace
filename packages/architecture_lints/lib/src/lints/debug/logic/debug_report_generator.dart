import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/context/component_context.dart';

class DebugReportGenerator {
  final ArchitectureConfig config;
  final FileResolver fileResolver;
  final ComponentContext? component;
  final String? error;

  DebugReportGenerator({
    required this.config,
    required this.fileResolver,
    required this.component,
    this.error,
  });

  /// Generates the global file status report.
  String generateHeaderReport(String path) {
    final sb = StringBuffer();

    if (error != null) {
      sb
        ..writeln('🔥 FATAL CONFIGURATION / RUNTIME ERROR 🔥')
        ..writeln(error)
        ..writeln('==================================================\n');
    }

    final filename = path.split(RegExp(r'[/\\]')).last;
    sb
      ..writeln('[DEBUG: FILE CONTEXT] "$filename"')
      ..writeln('Path: $path')
      ..writeln('--------------------------------------------------');

    _writeComponentContext(sb);

    // Registry Report
    sb
      ..writeln(_generateRegistry())
      ..writeln('\n==================================================');
    return sb.toString();
  }

  /// Generates the specific report for an AST Node.
  String generate({
    required String typeLabel,
    required String name,
    required String path,
    DartType? dartType,
    Element? element,
    AstNode? astNode,
    String? extraInfo,
  }) {
    final sb = StringBuffer()
      ..writeln('[DEBUG: $typeLabel] "$name"')
      ..writeln('==================================================');

    // 1. Architectural Context
    _writeComponentContext(sb);

    // 2. Element Analysis (Generic)
    if (dartType != null || element != null || extraInfo != null) {
      sb.writeln('\n🔬 ANALYSIS');
      if (dartType != null) {
        sb.writeln('   • Type:    "${dartType.getDisplayString()}"');
        if (dartType.alias != null) {
          sb.writeln('   • Alias:   "${dartType.alias!.element.name}"');
        }
      }
      if (element != null) {
        final kindName = element.kind.displayName;
        sb.writeln('   • Element: "${element.name}" ($kindName)');

        // Show import source
        final lib = element.library;
        if (lib != null) {
          final uri = lib.firstFragment.source.uri.toString();
          sb.writeln('   • Source:  "$uri"');
        }
      }
      if (extraInfo != null && extraInfo.isNotEmpty) {
        sb.writeln('   • Info:    $extraInfo');
      }
    }

    // 3. Structural Details (Specific Nodes)
    if (astNode != null) {
      _writeNodeDetails(sb, astNode);
    }

    // 4. Scoring Log
    if (component?.debugScoreLog != null) {
      sb
        ..writeln('\n🧮 RESOLUTION LOG')
        ..write(component!.debugScoreLog!.trimRight());
    }

    sb.writeln('\n==================================================');
    return sb.toString();
  }

  void _writeNodeDetails(StringBuffer sb, AstNode node) {
    if (node is ClassDeclaration) {
      sb.writeln('\n🏗️ CLASS STRUCTURE');
      final el = node.declaredFragment?.element;
      if (el != null) {
        final modifiers = <String>[];
        if (el.isAbstract) modifiers.add('abstract');
        if (el.isSealed) modifiers.add('sealed');
        if (el.isInterface) modifiers.add('interface');
        if (el.isBase) modifiers.add('base');
        if (el.isFinal) modifiers.add('final');
        if (el.isMixinClass) modifiers.add('mixin');

        sb.writeln('   • Modifiers: ${modifiers.isEmpty ? 'None' : modifiers.join(', ')}');

        final supertypes = el.allSupertypes
            .map((t) => t.element.name)
            .whereType<String>()
            .where((n) => n != 'Object')
            .toList();

        sb.writeln('   • Hierarchy: ${_formatList(supertypes)}');
      }
    } else if (node is MethodDeclaration) {
      sb
        ..writeln('\n🏗️ METHOD DETAILS')
        ..writeln('   • Static: ${node.isStatic}')
        ..writeln('   • Return: ${node.returnType?.toSource() ?? 'dynamic'}')
        ..writeln('   • Params: ${node.parameters?.parameters.length ?? 0}');
    }

    if (node is FormalParameter) {
      sb
        ..writeln('\n🏗️ PARAMETER DETAILS')
        ..writeln('   • Kind: ${node.isNamed ? "Named" : "Positional"}')
        ..writeln('   • Required: ${node.isRequired}')
        ..writeln('   • Explicit Type: ${node.isExplicitlyTyped}');

      if (node is DefaultFormalParameter) {
        sb.writeln('   • Default Value: ${node.defaultValue?.toSource() ?? "null"}');
      }
    } else if (node is ConstructorDeclaration) {
      sb
        ..writeln('\n🏗️ CONSTRUCTOR DETAILS')
        ..writeln('   • Factory: ${node.factoryKeyword != null}')
        ..writeln('   • Const: ${node.constKeyword != null}')
        ..writeln('   • Name: ${node.name?.lexeme ?? "(unnamed)"}');
    } else if (node is FieldDeclaration) {
      sb
        ..writeln('\n🏗️ FIELD DETAILS')
        ..writeln('   • Static: ${node.isStatic}');
    }
  }

  void _writeComponentContext(StringBuffer sb) {
    if (component != null) {
      sb.writeln('✅ COMPONENT: "${component!.id}"');
      if (component!.module != null) {
        sb.writeln(
          '   • Module: "${component!.module!.key}" (Instance: "${component!.module!.name}")',
        );
      } else {
        sb.writeln('   • Module: <Global/Core>');
      }
      sb.writeln('   • Mode:   ${component!.definition.mode.name.toUpperCase()}');
    } else {
      sb.writeln('❌ COMPONENT: <NULL> (Orphan)');
    }
  }

  String _generateRegistry() {
    final sb = StringBuffer()
      ..writeln('\n📊 CONFIGURATION REGISTRY')
      ..writeln('--------------------------------------------------');

    if (config.modules.isNotEmpty) {
      sb.writeln('📦 MODULES (${config.modules.length})');
      for (final m in config.modules) {
        sb.writeln('   - ${m.key} (Path: "${m.path}")');
      }
    }

    if (config.components.isNotEmpty) {
      sb.writeln('\n🧩 COMPONENTS (${config.components.length})');
      for (final c in config.components) {
        final segments = c.id.split('.');
        final depth = segments.length - 1;
        final indent = ' ' * (depth * 2);
        final name = segments.last;
        sb.writeln('   $indent- $name [${c.id}]');
      }
    } else {
      sb.writeln('\n⚠️ No Components Loaded!');
    }

    return sb.toString();
  }

  String _formatList(List<String> items) {
    if (items.isEmpty) return '[]';
    return '[ ${items.join(", ")} ]';
  }
}
