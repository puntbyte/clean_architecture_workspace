// lib/src/lints/error_handling/convert_exceptions_to_failures.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:architecture_lints/src/models/configs/error_handlers_config.dart';
import 'package:architecture_lints/src/models/configs/type_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that enforces 1-to-1 mapping between Exceptions and Failures in catch blocks.
///
/// **Category:** Error Handling
///
/// **Reasoning:** To preserve the abstraction of the Domain layer, Repositories must
/// explicitly convert infrastructure errors (Exceptions) into domain errors (Failures).
/// Catching a specific exception (e.g., `ServerException`) but returning a generic
/// or incorrect failure (e.g., `CacheFailure`) hides the true cause of the error
/// and makes debugging difficult.
class ConvertExceptionsToFailures extends ArchitectureRule {
  static const _code = LintCode(
    name: 'convert_exceptions_to_failures',
    problemMessage: 'Incorrect exception mapping. Expected to return `{0}` when catching `{1}`.',
    correctionMessage: 'Return `{0}` inside this catch block.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ConvertExceptionsToFailures({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final component = layerResolver.getComponent(resolver.source.fullName);

    // 1. Config Lookup
    final rule =
        definition.errorHandlers.ruleFor(component) ??
        definition.errorHandlers.ruleFor(component.layer);

    if (rule == null || rule.conversions.isEmpty) return;

    context.registry.addCatchClause((node) {
      // 2. Identify Caught Exception Type
      final exceptionType = node.exceptionType?.type;

      // Find the specific conversion rule that applies to this exception
      final conversion = _findConversion(exceptionType, rule.conversions);
      if (conversion == null) return; // No rule for this exception type

      // Resolve the expected Failure type name for the message
      final expectedFailureDef = definition.typeDefinitions.get(conversion.toType);
      final expectedFailureName = expectedFailureDef?.name ?? conversion.toType;
      final caughtExceptionName = exceptionType?.element?.name ?? 'Exception';

      // 3. Inspect the Return Statement(s) in the Catch Block
      var hasValidReturn = false;

      // We traverse the catch block to find return statements.
      // Note: This simple traversal doesn't handle nested functions inside the catch block,
      // but is sufficient for standard repo patterns.
      node.body.visitChildren(
        _ReturnStatementVisitor((returnNode) {
          if (_isValidReturn(returnNode, conversion.toType)) {
            hasValidReturn = true;
          } else {
            // Found a return, but it's wrong type. Report it specifically.
            reporter.atNode(
              returnNode,
              _code,
              arguments: [expectedFailureName, caughtExceptionName],
            );
            hasValidReturn = true; // Mark as visited/reported to avoid double reporting
          }
        }),
      );

      // If we didn't find ANY return statement (e.g. it rethrows or just logs),
      // other lints (disallow_throwing) might catch it, or it might be void.
      // We strictly check explicit returns here.
    });
  }

  /// Finds the matching conversion rule for the caught exception type.
  ConversionDetail? _findConversion(DartType? caughtType, List<ConversionDetail> conversions) {
    for (final conversion in conversions) {
      final fromTypeDef = definition.typeDefinitions.get(conversion.fromType);

      // If caughtType is null (generic `catch(e)`), matching a rule for 'dynamic'/'Object'
      // or a base Exception type logic would go here. For now, we check explicit types.
      if (caughtType != null && fromTypeDef != null) {
        if (_matchesType(caughtType, fromTypeDef)) {
          return conversion;
        }
      }
    }
    return null;
  }

  /// Checks if the return statement returns the Expected Failure Type.
  /// It handles `return Left(ExpectedFailure())` or `return ExpectedFailure()`.
  bool _isValidReturn(ReturnStatement node, String targetTypeKey) {
    final expression = node.expression;
    if (expression == null) return false;

    final targetTypeDef = definition.typeDefinitions.get(targetTypeKey);
    if (targetTypeDef == null) return false;

    // Case A: Direct Return (e.g. `return ServerFailure();`)
    if (_matchesType(expression.staticType, targetTypeDef)) {
      return true;
    }

    // Case B: Wrapped Return (e.g. `return Left(ServerFailure());`)
    // We verify if it is a Wrapper (Right/Left) and check its argument/type argument.
    if (expression is InstanceCreationExpression) {
      // Check constructor arguments: Left(ServerFailure())
      final arg = expression.argumentList.arguments.firstOrNull;
      if (arg != null && _matchesType(arg.staticType, targetTypeDef)) {
        return true;
      }
    } else if (expression is MethodInvocation) {
      // Check method args: left(ServerFailure())
      final arg = expression.argumentList.arguments.firstOrNull;
      if (arg != null && _matchesType(arg.staticType, targetTypeDef)) {
        return true;
      }
    }

    return false;
  }

  bool _matchesType(DartType? type, TypeRule definition) {
    final element = type?.element;
    if (element == null) return false;

    if (element.name != definition.name) return false;

    if (definition.import != null) {
      final source = element.library?.firstFragment.source;
      if (source == null) return false;

      if (source.uri.isScheme('dart') && definition.import!.startsWith('dart:')) {
        return source.uri.toString() == definition.import;
      }
      return source.uri.toString().endsWith(definition.import!);
    }
    return true;
  }
}

/// A simple visitor to find ReturnStatements inside a block.
class _ReturnStatementVisitor extends RecursiveAstVisitor<void> {
  final void Function(ReturnStatement) onReturn;

  _ReturnStatementVisitor(this.onReturn);

  @override
  void visitReturnStatement(ReturnStatement node) {
    onReturn(node);
  }
}
