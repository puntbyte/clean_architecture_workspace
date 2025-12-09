import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/config/enums/component_kind.dart';
import 'package:architecture_lints/src/config/enums/component_modifier.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/refinement/refinement_context.dart';
import 'package:architecture_lints/src/core/resolver/refinement/refinement_strategy.dart';
import 'package:architecture_lints/src/core/resolver/refinement/score_log.dart';
import 'package:architecture_lints/src/core/resolver/refinement/score_weight.dart';

class StructureStrategy implements RefinementStrategy {
  @override
  void evaluate({
    required ScoreLog log,
    required RefinementContext context,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
  }) {
    final node = context.mainNode;
    if (node == null) return; // Can't check structure without a node

    final cConfig = log.candidate.component;

    // 1. Kind Check
    if (cConfig.kinds.isNotEmpty) {
      final kind = _identifyKind(node);
      if (kind != null) {
        if (cConfig.kinds.contains(kind)) {
          log.add(ScoreWeight.medium.value, 'KIND: Matched ${kind.name}');
        } else {
          // Veto: If config requires Enum but we found Class, this is NOT the component.
          log.add(ScoreWeight.veto.value, 'KIND: Mismatch (Req: ${cConfig.kinds})');
        }
      }
    }

    // 2. Modifier Check (CRITICAL for Interface vs Implementation resolution)
    if (cConfig.modifiers.isNotEmpty && node is ClassDeclaration) {
      if (_checkModifiers(node, cConfig.modifiers)) {
        log.add(ScoreWeight.medium.value, 'MODS: Matched requirements');
      } else {
        // Veto: If config requires Abstract but class is Concrete, disqualified.
        log.add(ScoreWeight.veto.value, 'MODS: Mismatch (Req: ${cConfig.modifiers})');
      }
    }
  }

  ComponentKind? _identifyKind(NamedCompilationUnitMember node) {
    if (node is ClassDeclaration) return ComponentKind.class$;
    if (node is MixinDeclaration) return ComponentKind.mixin$;
    if (node is EnumDeclaration) return ComponentKind.enum$;
    if (node is ExtensionDeclaration) return ComponentKind.extension$;
    if (node is FunctionTypeAlias) return ComponentKind.typedef$;
    if (node is GenericTypeAlias) return ComponentKind.typedef$;
    if (node is FunctionDeclaration) return ComponentKind.function;
    return null;
  }

  bool _checkModifiers(ClassDeclaration node, List<ComponentModifier> requiredModifiers) {
    final element = node.declaredFragment?.element;
    if (element == null) return false;

    for (final mod in requiredModifiers) {
      switch(mod) {
        case ComponentModifier.abstract:
          if (!element.isAbstract && !element.isInterface && !element.isMixinClass) return false;
          break;
        case ComponentModifier.sealed: if (!element.isSealed) return false; break;
        case ComponentModifier.base: if (!element.isBase) return false; break;
        case ComponentModifier.interface: if (!element.isInterface) return false; break;
        case ComponentModifier.final$: if (!element.isFinal) return false; break;
        case ComponentModifier.mixin: if (!element.isMixinClass) return false; break;
      }
    }
    return true;
  }
}