// lib/src/utils/type_checker_utils.dart

import 'package:analyzer/dart/element/type.dart';
import 'package:clean_architecture_lints/src/analysis/component_kind.dart';
import 'package:clean_architecture_lints/src/analysis/component_resolver.dart';

/// A utility class with static methods for performing semantic checks on DartTypes.
class TypeCheckerUtils {
  const TypeCheckerUtils._();

  /// Recursively checks if a type or any of its generic arguments is a "Model"
  /// by checking its file location via the [ComponentResolver].
  static bool isModelType(DartType? type, ComponentResolver resolver) {
    if (type == null) return false;

    final source = type.element?.firstFragment.libraryFragment?.source;
    if (source != null) {
      final component = resolver.resolveComponent(source.fullName);
      if (component?.kind == ComponentKind.dataModel) {
        return true;
      }
    }

    if (type is InterfaceType) {
      return type.typeArguments.any((arg) => isModelType(arg, resolver));
    }
    return false;
  }

  /// Recursively checks if a type or any of its generic arguments is an "Entity"
  /// by checking its file location via the [ComponentResolver].
  static bool isEntityType(DartType? type, ComponentResolver resolver) {
    if (type == null) return false;

    final source = type.element?.firstFragment.libraryFragment?.source;
    if (source != null) {
      final component = resolver.resolveComponent(source.fullName);
      if (component?.kind == ComponentKind.businessObject) {
        return true;
      }
    }

    if (type is InterfaceType) {
      return type.typeArguments.any((arg) => isEntityType(arg, resolver));
    }
    return false;
  }

  /// Recursively checks if a type or any of its generic arguments originates from
  /// the Flutter SDK (`package:flutter` or `dart:ui`).
  static bool isFlutterType(DartType? type) {
    if (type == null) return false;

    final library = type.element?.library;
    if (library != null) {
      final uri = library.uri;
      final isFlutterPackage =
          uri.isScheme('package') &&
          uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first == 'flutter';
      final isDartUi =
          uri.isScheme('dart') && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'ui';
      if (isFlutterPackage || isDartUi) {
        return true;
      }
    }

    if (type is InterfaceType) {
      return type.typeArguments.any(isFlutterType);
    }
    return false;
  }
}
