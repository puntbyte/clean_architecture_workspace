import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/schema/member_constraint.dart';

mixin MemberLogic {
  /// Checks if [member] matches the criteria in [constraint].
  bool matchesConstraint(ClassMember member, MemberConstraint constraint) {
    final element = _getElement(member);
    if (element == null) return false;

    // 1. Kind Match
    if (constraint.kind != null) {
      final kind = _getKind(member);
      if (kind != constraint.kind && constraint.kind != 'override') {
        return false;
      }
      // Special handle for 'override' kind (checks annotation)
      if (constraint.kind == 'override' && !_hasOverrideAnnotation(member)) {
        return false;
      }
    }

    // 2. Visibility Match
    if (constraint.visibility != null) {
      final isPublic = !element.isPrivate;
      if (constraint.visibility == 'public' && !isPublic) return false;
      if (constraint.visibility == 'private' && isPublic) return false;
    }

    // 3. Modifier Match
    if (constraint.modifier != null) {
      if (!_hasModifier(member, element, constraint.modifier!)) return false;
    }

    // 4. Identifier Match (Regex or Exact)
    if (constraint.identifiers.isNotEmpty) {
      final name = element.name;
      if (name == null) return false;

      bool idMatch = false;
      for (final pattern in constraint.identifiers) {
        if (RegExp(pattern).hasMatch(name)) {
          idMatch = true;
          break;
        }
      }
      if (!idMatch) return false;
    }

    return true;
  }

  Element? _getElement(ClassMember member) {
    if (member is MethodDeclaration) return member.declaredFragment?.element;
    if (member is FieldDeclaration) return member.fields.variables.first.declaredFragment?.element;
    if (member is ConstructorDeclaration) return member.declaredFragment?.element;
    return null;
  }

  String _getKind(ClassMember member) {
    if (member is ConstructorDeclaration) return 'constructor';
    if (member is MethodDeclaration) {
      if (member.isGetter) return 'getter';
      if (member.isSetter) return 'setter';
      return 'method';
    }
    if (member is FieldDeclaration) return 'field';
    return 'unknown';
  }

  bool _hasOverrideAnnotation(ClassMember member) {
    return member.metadata.any((a) => a.name.name == 'override');
  }

  bool _hasModifier(ClassMember member, Element element, String modifier) {
    switch (modifier) {
      case 'static':
        if (element is ExecutableElement) return element.isStatic;
        if (element is FieldElement) return element.isStatic;
        return false;
      case 'final':
        if (element is FieldElement) return element.isFinal;
        return false;
      case 'const':
        if (element is FieldElement) return element.isConst;
        if (element is ConstructorElement) return element.isConst;
        return false;
      case 'late':
        if (element is FieldElement) return element.isLate;
        return false;
      default:
        return false;
    }
  }
}