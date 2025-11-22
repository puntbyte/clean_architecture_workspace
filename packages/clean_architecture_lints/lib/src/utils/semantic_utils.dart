// lib/src/utils/semantic_utils.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';

class SemanticUtils {
  const SemanticUtils._();

  /// Checks if an executable element is an override of a member from an
  /// architectural contract (a Port).
  static bool isArchitecturalOverride(ExecutableElement element, LayerResolver layerResolver) {
    final enclosingClass = element.enclosingElement;
    if (enclosingClass is! InterfaceElement) return false;
    if (element.isStatic) return false;

    final elementName = element.name;
    if (elementName == null) return false;

    for (final supertype in enclosingClass.allSupertypes) {
      final supertypeElement = supertype.element;
      // FIX: Use the robust library source check
      final source = supertypeElement.library?.firstFragment.source;
      if (source == null) continue;

      // Check if this supertype is defined in a "port" file.
      if (layerResolver.getComponent(source.fullName) == ArchComponent.port) {
        // Check methods
        if (element is MethodElement) {
          if (supertypeElement.methods.any((m) => m.name == elementName)) return true;
        }

        // Check getters/setters
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
}
