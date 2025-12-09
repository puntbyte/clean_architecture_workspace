import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
// Hide LintCode to avoid conflict
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DebugComponentIdentity extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'debug_component_identity',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.INFO,
  );

  const DebugComponentIdentity() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    void reportOn({
      required Object nodeOrToken,
      required String typeLabel,
      required String name,
      DartType? dartType,
      Element? element,
      AstNode? astNode,
      String? extraInfo,
    }) {
      final message = _generateDebugReport(
        typeLabel: typeLabel,
        name: name,
        path: resolver.path,
        component: component,
        dartType: dartType,
        element: element,
        astNode: astNode,
        extraInfo: extraInfo,
        fileResolver: fileResolver,
      );

      if (nodeOrToken is AstNode) {
        reporter.atNode(nodeOrToken, _code, arguments: [message]);
      } else if (nodeOrToken is Token) {
        reporter.atToken(nodeOrToken, _code, arguments: [message]);
      }
    }

    // =========================================================================
    // 1. FILE CONTEXT (Header)
    // =========================================================================
    context.registry.addCompilationUnit((node) {
      final target = node.directives.firstOrNull ??
          node.declarations.firstOrNull;

      if (target != null) {
        // Find a token to hang the file report on
        final token = target is AnnotatedNode
            ? target.firstTokenAfterCommentAndMetadata
            : target.beginToken;

        reportOn(
          nodeOrToken: token,
          typeLabel: 'FILE CONTEXT',
          name: resolver.path.split('/').last,
        );
      }
    });

    // =========================================================================
    // 2. DIRECTIVES (Imports/Exports)
    // =========================================================================
    context.registry.addImportDirective((node) {
      final libImport = node.libraryImport;
      final importedLib = libImport?.importedLibrary;

      var info = '';
      if (importedLib != null) {
        info = 'Source: ${importedLib.firstFragment.source.fullName}';
      }

      reportOn(
        nodeOrToken: node.uri,
        typeLabel: 'Import',
        name: node.uri.stringValue ?? '???',
        element: null, // LibraryImport is not an Element we want to display as "Element: ..."
        extraInfo: info,
      );
    });

    context.registry.addExportDirective((node) {
      reportOn(
        nodeOrToken: node.uri,
        typeLabel: 'Export',
        name: node.uri.stringValue ?? '???',
      );
    });

    context.registry.addAnnotation((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Annotation',
        name: node.name.name,
        element: node.element,
      );
    });

    // =========================================================================
    // 3. DEFINITIONS (Classes, Methods, Vars)
    // =========================================================================

    context.registry.addClassDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Class Def',
        name: node.name.lexeme,
        astNode: node, // Pass node for Structure analysis
        element: node.declaredFragment?.element,
      );
    });

    context.registry.addMixinDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Mixin Def',
        name: node.name.lexeme,
        element: node.declaredFragment?.element,
      );
    });

    context.registry.addEnumDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Enum Def',
        name: node.name.lexeme,
        element: node.declaredFragment?.element,
      );
    });

    context.registry.addExtensionDeclaration((node) {
      reportOn(
        nodeOrToken: node.name ?? node.firstTokenAfterCommentAndMetadata,
        typeLabel: 'Extension Def',
        name: node.name?.lexeme ?? '<unnamed>',
        element: node.declaredFragment?.element,
      );
    });

    context.registry.addConstructorDeclaration((node) {
      reportOn(
        nodeOrToken: node.name ?? node.returnType,
        typeLabel: 'Constructor',
        name: node.name?.lexeme ?? node.returnType.name,
        element: node.declaredFragment?.element,
      );
    });

    context.registry.addFieldDeclaration((node) {
      for (final variable in node.fields.variables) {
        reportOn(
          nodeOrToken: variable.name,
          typeLabel: 'Field',
          name: variable.name.lexeme,
          dartType: variable.declaredElement?.type,
          element: variable.declaredElement,
        );
      }
    });

    context.registry.addMethodDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Method',
        name: node.name.lexeme,
        dartType: node.returnType?.type,
        element: node.declaredFragment?.element,
      );
    });

    context.registry.addVariableDeclaration((node) {
      // Local variables (exclude fields which are handled above)
      if (node.parent?.parent is! FieldDeclaration) {
        reportOn(
          nodeOrToken: node.name,
          typeLabel: 'Variable',
          name: node.name.lexeme,
          dartType: node.declaredElement?.type,
        );
      }
    });

    context.registry.addFormalParameter((node) {
      final name = node.name?.lexeme ?? '<unnamed>';
      final type = node.declaredFragment?.element.type;
      reportOn(
        nodeOrToken: node.name ?? node,
        typeLabel: 'Parameter',
        name: name,
        dartType: type,
      );
    });

    // =========================================================================
    // 4. TYPE REFERENCES (Inheritance & Usage)
    // =========================================================================

    context.registry.addNamedType((node) {
      // Avoid highlighting definitions themselves
      if (node.parent is ClassDeclaration ||
          node.parent is ConstructorDeclaration ||
          node.parent is MethodDeclaration) {
        // Note: We DO want Extends/Implements/With to be highlighted for debugging inheritance
        return;
      }

      reportOn(
        nodeOrToken: node.name2,
        typeLabel: 'Type Ref',
        name: node.name2.lexeme,
        dartType: node.type,
        element: node.element,
      );
    });

    // =========================================================================
    // 5. FLOW & LOGIC
    // =========================================================================

    context.registry.addReturnStatement((node) {
      final expression = node.expression;
      if (expression != null) {
        var source = expression.toSource();
        if (source.length > 30) source = '${source.substring(0, 27)}...';
        reportOn(
          nodeOrToken: expression,
          typeLabel: 'Return',
          name: source,
          dartType: expression.staticType,
        );
      }
    });

    context.registry.addThrowExpression((node) {
      final type = node.expression.staticType;
      reportOn(
        nodeOrToken: node,
        typeLabel: 'Throw',
        name: type?.getDisplayString() ?? 'dynamic',
        dartType: type,
      );
    });

    context.registry.addMethodInvocation((node) {
      reportOn(
        nodeOrToken: node.methodName,
        typeLabel: 'Invocation',
        name: node.methodName.name,
        dartType: node.staticType,
        element: node.methodName.element,
      );
    });

    context.registry.addInstanceCreationExpression((node) {
      // Correct way to get element for ConstructorName
      final cName = node.constructorName;
      final element = cName.name?.element; // For named constructors .from()
      // Fallback for unnamed could be harder to reach via element directly on name,
      // usually staticElement on ConstructorName worked but is deprecated.
      // We rely on staticType for basic info.

      reportOn(
        nodeOrToken: cName,
        typeLabel: 'Instantiation',
        name: cName.toSource(),
        dartType: node.staticType,
        element: element,
      );
    });
  }

  String _generateDebugReport({
    required String typeLabel,
    required String name,
    required String path,
    required ComponentContext? component,
    required FileResolver fileResolver,
    DartType? dartType,
    Element? element,
    AstNode? astNode,
    String? extraInfo,
  }) {
    final sb = StringBuffer();
    sb.writeln('[DEBUG: $typeLabel] "$name"');
    sb.writeln('==================================================');

    // 1. RESOLUTION RESULT
    if (component != null) {
      sb.writeln('✅ RESOLVED: "${component.id}"');
      if (component.module != null) {
        sb.writeln('📦 Module:   "${component.module!.key}"');
      }
      sb.writeln('📂 Mode:     ${component.config.mode.name}');
    } else {
      sb.writeln('❌ RESOLVED: <NULL> (Orphan File)');
    }

    // 2. ELEMENT & TYPE ANALYSIS
    if (dartType != null || element != null || extraInfo != null) {
      sb.writeln('\n🔬 ANALYSIS:');
      if (dartType != null) {
        sb.writeln('   • Type:    "${dartType.getDisplayString()}"');
        if (dartType.alias != null) {
          sb.writeln('   • Alias:   "${dartType.alias!.element.name}"');
        }
      }
      if (element != null) {
        final kindName = element.kind.displayName;
        sb.writeln('   • Element: "${element.name}" ($kindName)');

        final lib = element.library;
        if (lib != null) {
          final uri = lib.firstFragment.source.uri.toString();
          sb.writeln('   • Import:  "$uri"');
        }
      }
      if (extraInfo != null) {
        sb.writeln('   • Info:    $extraInfo');
      }
    }

    // 3. STRUCTURAL ANALYSIS (For Classes/Mixins)
    if (astNode is ClassDeclaration) {
      sb.writeln('\n🏗️ STRUCTURE:');
      final el = astNode.declaredFragment?.element;
      if (el != null) {
        sb.writeln('   • Abstract? ${el.isAbstract}');
        sb.writeln('   • Interface? ${el.isInterface}');

        final supertypes = el.allSupertypes
            .map((t) => t.element.name)
            .whereType<String>()
            .where((n) => n != 'Object')
            .toList();

        sb.writeln('   • Hierarchy: ${_formatList(supertypes)}');
      }
    }

    // 4. SCORING LOG
    if (component?.debugScoreLog != null) {
      sb.writeln('\n🧮 SCORING LOG:');
      sb.write(component!.debugScoreLog!.trimRight());
    }

    sb.writeln('\n==================================================');
    return sb.toString();
  }

  String _formatList(List<String> items) {
    if (items.isEmpty) return '[]';
    return '[ ${items.join(", ")} ]';
  }
}