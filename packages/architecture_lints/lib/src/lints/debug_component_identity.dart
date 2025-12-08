import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
// Hide LintCode to avoid conflict with custom_lint_builder
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
    // Helper to report on any node with optional Type info
    void reportOn({
      required Object nodeOrToken, // AstNode or Token
      required String typeLabel, // "Class", "Return Value", "Invocation"
      required String name, // "User", "Future<void>"
      DartType? dartType, // Optional: The static type being analyzed
      AstNode? astNode, // Optional: The node itself for structural inspection
    }) {
      final message = _generateDebugReport(
        typeLabel: typeLabel,
        name: name,
        path: resolver.path,
        component: component,
        dartType: dartType,
        astNode: astNode,
        fileResolver: fileResolver,
      );

      if (nodeOrToken is AstNode) {
        reporter.atNode(nodeOrToken, _code, arguments: [message]);
      } else if (nodeOrToken is Token) {
        reporter.atToken(nodeOrToken, _code, arguments: [message]);
      }
    }

    // --- 1. DEFINITIONS ---

    context.registry.addClassDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Class Definition',
        name: node.name.lexeme,
        astNode: node, // Pass node to inspect modifiers/extends
      );
    });

    context.registry.addMethodDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Method Definition',
        name: node.name.lexeme,
        dartType: node.returnType?.type,
      );
    });

    context.registry.addVariableDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Variable Definition',
        name: node.name.lexeme,
        dartType: node.declaredElement?.type,
      );
    });

    context.registry.addFormalParameter((node) {
      final name = node.name?.lexeme ?? '<unnamed>';
      final type = node.declaredFragment?.element.type;
      reportOn(
        nodeOrToken: node,
        typeLabel: 'Parameter',
        name: name,
        dartType: type,
      );
    });

    // --- 2. EXPRESSIONS & FLOW ---

    // Returns
    context.registry.addReturnStatement((node) {
      final expression = node.expression;
      if (expression != null) {
        var source = expression.toSource();
        if (source.length > 30) source = '${source.substring(0, 27)}...';
        reportOn(
          nodeOrToken: expression,
          typeLabel: 'Return Value',
          name: source,
          dartType: expression.staticType,
        );
      }
    });

    // Throws
    context.registry.addThrowExpression((node) {
      final type = node.expression.staticType;
      reportOn(
        nodeOrToken: node,
        typeLabel: 'Throw',
        name: type?.getDisplayString() ?? 'dynamic',
        dartType: type,
      );
    });

    // Method Invocations
    context.registry.addMethodInvocation((node) {
      reportOn(
        nodeOrToken: node.methodName,
        typeLabel: 'Invocation',
        name: node.methodName.name,
        dartType: node.staticType,
      );
    });

    // Instantiations
    context.registry.addInstanceCreationExpression((node) {
      reportOn(
        nodeOrToken: node.constructorName,
        typeLabel: 'Instantiation',
        name: node.constructorName.toSource(),
        dartType: node.staticType,
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
    AstNode? astNode,
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
      sb.writeln('❌ RESOLVED: <NULL> (Orphan)');
    }

    // 2. SCORING LOG (Crucial for debugging Refiner logic)
    if (component?.debugScoreLog != null) {
      sb.writeln('\n🧮 SCORING LOG (Why was this chosen?):');
      sb.writeln(component!.debugScoreLog!.trimRight());
    } else {
      // Fallback if no log exists (e.g. refiner wasn't run)
      final candidates = fileResolver.resolveAllCandidates(path);
      sb.writeln('\n📊 COMPETITION (Raw Path Match):');
      if (candidates.isEmpty) {
        sb.writeln('   (No components match path)');
      } else {
        for (final c in candidates) {
          final isWinner = component?.id == c.component.id;
          sb.writeln('${isWinner ? "➤" : " "} ${c.component.id} (Idx:${c.matchIndex}, Len:${c.matchLength})');
        }
      }
    }

    // 3. STRUCTURE ANALYSIS (If highlighting a class)
    if (astNode is ClassDeclaration) {
      sb.writeln('\n🏗️ CLASS STRUCTURE:');
      final element = astNode.declaredFragment?.element;
      if (element != null) {
        sb.writeln('   • Name: "${element.name}"');
        sb.writeln('   • Abstract? ${element.isAbstract}');
        sb.writeln('   • Interface? ${element.isInterface}');
        sb.writeln('   • Mixin Class? ${element.isMixinClass}');

        final supertypes = element.allSupertypes
            .map((t) => t.element.name)
            .where((n) => n != 'Object')
            .join(', ');
        sb.writeln('   • Hierarchy: [ $supertypes ]');
      }
    }

    // 4. TYPE ANALYSIS (If available)
    if (dartType != null) {
      sb.writeln('\n🔬 TYPE DETAILS:');
      sb.writeln('   • Display: "${dartType.getDisplayString()}"');
      final element = dartType.element;
      if (element != null) {
        sb.writeln('   • Element: ${element.name} (${element.kind.displayName})');
        final uri = element.library?.firstFragment.source.uri.toString();
        sb.writeln('   • Import:  $uri');
      }
      if (dartType.alias != null) {
        sb.writeln('   • Alias:   ${dartType.alias!.element.name}');
      }
    }

    sb.writeln('==================================================');
    return sb.toString();
  }
}