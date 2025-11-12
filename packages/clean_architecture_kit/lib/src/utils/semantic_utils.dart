import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:clean_architecture_kit/src/models/naming_config.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';

/// A utility class for common semantic analysis tasks.
///
/// These helpers inspect the fully resolved semantic model (`DartType`, `Element`)
/// to make robust architectural checks.
class SemanticUtils {
  const SemanticUtils._();

  /// Recursively checks if a type or any of its generic arguments is a "Model" by its file location.
  static bool isModelType(DartType? type, LayerResolver layerResolver) {
    if (type == null) return false;

    final source = type.element?.firstFragment.libraryFragment?.source;
    if (source != null && layerResolver.getSubLayer(source.fullName) == ArchSubLayer.model) {
      return true;
    }

    if (type is InterfaceType) {
      return type.typeArguments.any((arg) => isModelType(arg, layerResolver));
    }

    return false;
  }

  /// Recursively checks if a type or any of its generic arguments is an "Entity" by its file location.
  static bool isEntityType(DartType? type, LayerResolver layerResolver) {
    if (type == null) return false;

    final source = type.element?.firstFragment.libraryFragment?.source;
    if (source != null && layerResolver.getSubLayer(source.fullName) == ArchSubLayer.entity) {
      return true;
    }

    if (type is InterfaceType) {
      return type.typeArguments.any((arg) => isEntityType(arg, layerResolver));
    }
    return false;
  }

  /// Recursively checks if a type or any of its generic arguments is from Flutter
  /// (`package:flutter` or `dart:ui`).
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

      if (isFlutterPackage || isDartUi) return true;
    }

    if (type is InterfaceType) return type.typeArguments.any(isFlutterType);

    return false;
  }

  /// Checks if a type's name matches the configured UseCase naming convention.
  static bool isUseCaseType(DartType? type, NamingConfig namingConfig) {
    if (type == null) return false;
    final typeName = type.element?.name;
    if (typeName == null) return false;
    return NamingUtils.validateName(name: typeName, template: namingConfig.useCase.pattern);
  }

  /// Checks if a type's name matches the configured Repository interface naming convention.
  static bool isRepositoryInterfaceType(DartType? type, NamingConfig namingConfig) {
    if (type == null) return false;
    final typeName = type.element?.name;
    if (typeName == null) return false;
    return NamingUtils.validateName(
      name: typeName,
      template: namingConfig.repository.pattern,
    );
  }

  /// Checks if a member is an architectural override of a method from a domain repository
  /// interface.
  static bool isArchitecturalOverride(ExecutableElement element, LayerResolver layerResolver) {
    final enclosingClass = element.enclosingElement;
    if (enclosingClass is! InterfaceElement) return false;

    final elementName = element.name;
    if (elementName == null) return false;

    for (final supertype in enclosingClass.allSupertypes) {
      final superElement = supertype.element;
      final source = superElement.firstFragment.libraryFragment.source;

      if (layerResolver.getSubLayer(source.fullName) == ArchSubLayer.domainRepository) {
        if (supertype.getMethod(elementName) != null || supertype.getGetter(elementName) != null) {
          return true;
        }
      }
    }
    return false;
  }
}
