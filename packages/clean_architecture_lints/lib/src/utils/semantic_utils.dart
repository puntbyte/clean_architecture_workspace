// lib/src/utils/semantic_utils.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';

/// A utility class for common semantic analysis tasks related to the element model.
class SemanticUtils {
  const SemanticUtils._();

  /// Checks if an executable element is an architectural override of a contract.
  ///
  /// An architectural override means the element implements or extends a member
  /// from a class that is defined in a domain 'contract' directory.
  static bool isArchitecturalOverride(ExecutableElement element, LayerResolver layerResolver) {
    // FIX 2: Check for a null name early. An element with no name cannot be an override.
    final elementName = element.name;
    if (elementName == null) return false;

    final enclosingClass = element.enclosingElement;
    if (enclosingClass is! InterfaceElement) return false;

    for (final supertype in enclosingClass.allSupertypes) {
      final path = _getSourcePath(supertype);
      if (path != null && layerResolver.getComponent(path) == ArchComponent.contract) {
        // Use the non-nullable elementName for lookups.
        if (supertype.getMethod(elementName) != null || supertype.getGetter(elementName) != null) {
          return true;
        }
      }
    }
    return false;
  }

  /// Recursively checks if a type or any of its generic arguments is from Flutter.
  static bool isFlutterType(DartType? type) {
    if (type == null) return false;

    // FIX 1: Use `library?.firstFragment.source.uri` to access the URI.
    final uri = type.element?.library?.firstFragment.source.uri;
    if (uri != null) {
      final isFlutterPackage = uri.isScheme('package') && uri.pathSegments.firstOrNull == 'flutter';
      final isDartUi = uri.isScheme('dart') && uri.pathSegments.firstOrNull == 'ui';
      if (isFlutterPackage || isDartUi) return true;
    }

    if (type is InterfaceType) {
      return type.typeArguments.any(isFlutterType);
    }
    return false;
  }

  /// Recursively checks if a type or any of its generic arguments is a specific
  /// architectural component by its file location.
  static bool isComponent(
      DartType? type,
      LayerResolver layerResolver,
      ArchComponent componentToFind,
      ) {
    if (type == null) return false;

    final path = _getSourcePath(type);
    if (path != null && layerResolver.getComponent(path) == componentToFind) {
      return true;
    }

    if (type is InterfaceType) {
      return type.typeArguments.any((arg) => isComponent(arg, layerResolver, componentToFind));
    }
    return false;
  }

  /// A robust helper to get the absolute file path from a DartType.
  static String? _getSourcePath(DartType? type) {
    // This helper was already correct and uses the modern API.
    return type?.element?.library?.firstFragment.source.fullName;
  }
}
