// lib/src/utils/ast/semantic_utils.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';

class SemanticUtils {
  const SemanticUtils._();

  /// Checks if an executable element overrides a member from an architectural contract.
  static bool isArchitecturalOverride(ExecutableElement element, LayerResolver layerResolver) {
    final enclosingClass = element.enclosingElement;
    if (enclosingClass is! InterfaceElement) return false;
    if (element.isStatic) return false;

    final elementName = element.name;
    if (elementName == null) return false;

    for (final supertype in enclosingClass.allSupertypes) {
      final supertypeElement = supertype.element;

      // Safe access to source
      final source = supertypeElement.library.firstFragment.source;

      // Check if this supertype is defined in a "port" file (Contract).
      if (layerResolver.getComponent(source.fullName) == ArchComponent.port) {
        if (element is MethodElement) {
          if (supertypeElement.methods.any((m) => m.name == elementName)) return true;
        }
        if (element is PropertyAccessorElement) {
          if (supertypeElement.getters.any((g) => g.name == elementName) ||
              supertypeElement.setters.any((s) => s.name == elementName)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  static bool isFlutterType(DartType? type) {
    if (type == null) return false;
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

  static bool isComponent(
      DartType? type,
      LayerResolver layerResolver,
      ArchComponent componentToFind,
      ) {
    if (type == null) return false;

    // Check type alias first
    if (type.alias case final alias?) {
      final path = alias.element.library?.firstFragment.source.fullName;
      if (path != null && layerResolver.getComponent(path) == componentToFind) {
        return true;
      }
    }

    // Check regular type
    final path = _getSourcePath(type);
    if (path != null && layerResolver.getComponent(path) == componentToFind) return true;

    if (type is InterfaceType) {
      return type.typeArguments.any((arg) => isComponent(arg, layerResolver, componentToFind));
    }
    return false;
  }

  static String? _getSourcePath(DartType? type) {
    // Handle type aliases
    if (type?.alias case final alias?) {
      return alias.element.library.firstFragment.source.fullName;
    }
    // Handle regular types
    return type?.element?.library?.firstFragment.source.fullName;
  }

  /*static bool isComponent(
    DartType? type,
    LayerResolver layerResolver,
    ArchComponent componentToFind,
  ) {
    if (type == null) return false;
    final path = _getSourcePath(type);
    if (path != null && layerResolver.getComponent(path) == componentToFind) return true;
    if (type is InterfaceType) {
      return type.typeArguments.any((arg) => isComponent(arg, layerResolver, componentToFind));
    }
    return false;
  }

  static String? _getSourcePath(DartType? type) {
    return type?.element?.library?.firstFragment.source.fullName;
  }

  */
}
