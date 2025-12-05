import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/schema/annotation_constraint.dart';

mixin AnnotationLogic {
  bool matchesConstraint(Annotation node, AnnotationConstraint constraint) {
    final element = node.element;

    // Resolve the class element of the annotation
    // Annotations usually resolve to a ConstructorElement (e.g. @Injectable() -> new Injectable())
    // or a PropertyAccessorElement (e.g. @override -> override get)
    // We want the enclosing Class or TopLevelVariable.

    String? name;
    String? uri;

    if (element is ConstructorElement) {
      name = element.enclosingElement.name; // Class name (e.g. Injectable)
      uri = element.library.firstFragment.source.uri.toString();
    } else if (element is PropertyAccessorElement) {
      name = element.name; // e.g. override
      uri = element.library.firstFragment.source.uri.toString();
    } else if (element is ClassElement) {
      name = element.name;
      uri = element.library.firstFragment.source.uri.toString();
    } else {
      // Fallback to syntactic name if unresolved (less accurate but better than nothing)
      name = node.name.name;
    }

    if (name == null) return false;

    // 1. Check Name
    if (constraint.types.contains(name)) {
      // 2. Check Import (if specified)
      if (constraint.import != null) {
        return uri == constraint.import;
      }
      return true;
    }

    return false;
  }

  String describeConstraint(AnnotationConstraint c) {
    return c.types.join(' or ');
  }
}