import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/enums/component_kind.dart';
import 'package:architecture_lints/src/config/enums/component_mode.dart';
import 'package:architecture_lints/src/config/enums/component_modifier.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:path/path.dart' as p;

extension _StringExt on String {
  String toPascalCase() {
    if (isEmpty) return this;
    return split(
      '_',
    ).map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join();
  }
}

class ComponentRefiner with InheritanceLogic, NamingLogic {
  final ArchitectureConfig config;
  final FileResolver fileResolver;

  ComponentRefiner(this.config, this.fileResolver);

  ComponentContext? refine({
    required String filePath,
    required ResolvedUnitResult unit,
  }) {
    // 1. Get Candidates
    var candidates = fileResolver.resolveAllCandidates(filePath);
    candidates = candidates.where((c) => c.component.mode != ComponentMode.namespace).toList();

    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return _buildContext(filePath, candidates.first.component);


    // 2. Identify Main Declaration
    final mainNode = _findMainDeclaration(unit.unit, filePath);
    final element = mainNode?.declaredFragment?.element;
    final className = element?.name;

    Candidate? bestCandidate;
    var bestScore = -99999.0;

    // Build Log
    final sb = StringBuffer()
      ..writeln('Analyzing "${className ?? 'Unknown'}" in "$filePath"')
      ..writeln('Main Node Type: ${mainNode.runtimeType}');
    if (element is ClassElement) {
      sb.writeln('Modifiers: abstract=${element.isAbstract}, interface=${element.isInterface}');
    }

    for (final candidate in candidates) {
      double score = 0;
      final cConfig = candidate.component;
      sb.writeln('\n--- Candidate: ${cConfig.id} ---');

      // [0] PATH & MODE
      score += candidate.matchIndex * 10;
      score += candidate.matchLength;

      if (cConfig.mode == ComponentMode.file) {
        score += 50;
        sb.writeln('  MODE: +50 (File)');
      } else if (cConfig.mode == ComponentMode.part) {
        score -= 50;
        sb.writeln('  MODE: -50 (Part)');
      }

      sb.writeln('  PATH_SCORE: ${(candidate.matchIndex * 10) + candidate.matchLength}');

      // [1] NAMING PATTERN
      if (cConfig.patterns.isNotEmpty && className != null) {
        var matchesPattern = false;
        var matchedPattern = '';
        for (final p in cConfig.patterns) {
          if (validateName(className, p)) {
            matchesPattern = true;
            matchedPattern = p;
            break;
          }
        }

        if (matchesPattern) {
          score += 40;
          score += matchedPattern.length;
          sb.writeln('  NAME: +${40 + matchedPattern.length} (Matched "$matchedPattern")');
        } else {
          score -= 5;
          sb.writeln('  NAME: -5 (No match)');
        }
      }

      // [1.5] CONVENTION HEURISTIC
      if (className != null) {
        final idLower = cConfig.id.toLowerCase();
        final nameLower = className.toLowerCase();

        final isImplComponent = idLower.contains('impl') || idLower.contains('implementation');
        final isImplClass = nameLower.endsWith('impl');

        if (isImplComponent && isImplClass) {
          score += 60;
          sb.writeln('  CONV: +60 (Impl/Impl match)');
        }
        if (!isImplComponent && isImplClass) {
          score -= 20;
          sb.writeln('  CONV: -20 (Impl class in Non-Impl component)');
        }
      }

      // [2] INHERITANCE
      if (element is InterfaceElement) {
        final inheritanceRules = config.inheritances.where((r) => r.onIds.contains(cConfig.id));

        for (final rule in inheritanceRules) {
          if (rule.required.isNotEmpty) {
            if (satisfiesRule(element, rule, config, fileResolver)) {
              final requiresComponent = rule.required.any((d) => d.component != null);
              if (requiresComponent) {
                score += 80;
                sb.writeln('  INHERIT: +80 (Satisfied Component Req)');
              } else {
                score += 40;
                sb.writeln('  INHERIT: +40 (Satisfied Type Req)');
              }
            } else {
              score -= 30;
              sb.writeln('  INHERIT: -30 (Failed Req)');
            }
          }
        }

        // Sibling Check
        if (_checkSiblingInheritance(element, candidate, candidates)) {
          score += 50;
          sb.writeln('  SIBLING: +50 (Implements Sibling)');
        }
      }

      // [3] STRUCTURE (Kind & Modifiers)
      if (mainNode != null) {
        // Kind
        if (cConfig.kinds.isNotEmpty) {
          final actualKind = _identifyKind(mainNode);
          if (actualKind != null && cConfig.kinds.contains(actualKind)) {
            score += 20;
            sb.writeln('  KIND: +20 (Matched ${actualKind.name})');
          } else {
            score -= 200;
            sb.writeln('  KIND: -200 (Mismatch. Req: ${cConfig.kinds})');
          }
        }

        // Modifiers
        if (cConfig.modifiers.isNotEmpty && mainNode is ClassDeclaration) {
          if (_checkModifiers(mainNode, cConfig.modifiers)) {
            score += 20;
            sb.writeln('  MODS: +20 (Matched)');
          } else {
            score -= 200;
            sb.writeln('  MODS: -200 (Mismatch. Req: ${cConfig.modifiers})');
          }
        }
      }

      // [4] TIE BREAKER
      final tie = cConfig.id.split('.').length * 0.1;
      score += tie;
      sb
        ..writeln('  TIE: +${tie.toStringAsFixed(1)}')
        ..writeln('  = TOTAL: $score');

      if (score > bestScore) {
        bestScore = score;
        bestCandidate = candidate;
      }
    }

    return _buildContext(
      filePath,
      bestCandidate?.component ?? candidates.first.component,
      sb.toString(),
    );
  }

  // --- HELPERS ---

  NamedCompilationUnitMember? _findMainDeclaration(CompilationUnit unit, String filePath) {
    final filename = p.basenameWithoutExtension(filePath);
    final expectedName = filename.toPascalCase();

    NamedCompilationUnitMember? exactMatch;
    NamedCompilationUnitMember? firstStructural;
    NamedCompilationUnitMember? firstPublic;

    for (final declaration in unit.declarations) {
      if (declaration is! NamedCompilationUnitMember) continue;

      final name = declaration.name.lexeme;

      // 1. Exact Match
      if (name == expectedName) {
        exactMatch = declaration;
        break; // Found perfect match
      }

      // 2. Identify Type (Structural vs Data)
      final isStructural =
          declaration is ClassDeclaration ||
          declaration is MixinDeclaration ||
          declaration is EnumDeclaration ||
          declaration is ExtensionDeclaration;

      if (!name.startsWith('_')) {
        if (isStructural && firstStructural == null) {
          firstStructural = declaration;
        }
        firstPublic ??= declaration;
      }
    }

    // Priority: Exact Name > First Public Class/Enum > First Public Anything > First Anything
    return exactMatch ??
        firstStructural ??
        firstPublic ??
        (unit.declarations.whereType<NamedCompilationUnitMember>().firstOrNull);
  }

  bool _checkSiblingInheritance(
    InterfaceElement element,
    Candidate current,
    List<Candidate> allCandidates,
  ) {
    final supertypes = element.allSupertypes;
    for (final supertype in supertypes) {
      final superElement = supertype.element;
      final library = superElement.library;

      final sourcePath = library.firstFragment.source.fullName;
      final superComponent = fileResolver.resolve(sourcePath);

      if (superComponent == null) continue;

      final isSibling = allCandidates.any((c) => c.component.id == superComponent.id);

      if (isSibling && superComponent.id != current.component.id) {
        if (current.component.id.length > superComponent.id.length) return true;
        if (current.component.id.toLowerCase().contains('impl') &&
            !superComponent.id.toLowerCase().contains('impl')) {
          return true;
        }
      }
    }
    return false;
  }

  ComponentKind? _identifyKind(NamedCompilationUnitMember node) {
    if (node is ClassDeclaration) return ComponentKind.class$;
    if (node is MixinDeclaration) return ComponentKind.mixin$;
    if (node is EnumDeclaration) return ComponentKind.enum$;
    if (node is ExtensionDeclaration) return ComponentKind.extension$;
    if (node is FunctionTypeAlias) return ComponentKind.typedef$;
    if (node is GenericTypeAlias) return ComponentKind.typedef$;
    if (node is FunctionDeclaration) return ComponentKind.function;
    if (node is TopLevelVariableDeclaration) return ComponentKind.variable;
    return null;
  }

  bool _checkModifiers(ClassDeclaration node, List<ComponentModifier> requiredModifiers) {
    final element = node.declaredFragment?.element;
    if (element == null) return false;
    for (final mod in requiredModifiers) {
      switch (mod) {
        case ComponentModifier.abstract:
          if (!element.isAbstract && !element.isInterface && !element.isMixinClass) return false;
        case ComponentModifier.sealed:
          if (!element.isSealed) return false;
        case ComponentModifier.base:
          if (!element.isBase) return false;
        case ComponentModifier.interface:
          if (!element.isInterface) return false;
        case ComponentModifier.final$:
          if (!element.isFinal) return false;
        case ComponentModifier.mixin:
          if (!element.isMixinClass) return false;
      }
    }
    return true;
  }

  ComponentContext _buildContext(String filePath, ComponentConfig config, [String? log]) {
    return ComponentContext(
      filePath: filePath,
      config: config,
      module: fileResolver.resolveModule(filePath),
      debugScoreLog: log,
    );
  }
}
