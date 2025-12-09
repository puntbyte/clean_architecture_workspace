import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/enums/component_kind.dart';
import 'package:architecture_lints/src/config/enums/component_mode.dart';
import 'package:architecture_lints/src/config/enums/component_modifier.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/refinement/score_log.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:path/path.dart' as p;

extension _StringExt on String {
  String toPascalCase() {
    if (isEmpty) return this;
    return split('_')
        .map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '')
        .join();
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
    candidates = candidates
        .where((c) => c.component.mode != ComponentMode.namespace)
        .toList();

    if (candidates.isEmpty) return null;

    if (candidates.length == 1) {
      final log = ScoreLog(candidates.first)..add(100, "MATCH: Only candidate");
      log.confidence = 1.0;
      return _buildContext(
          filePath, candidates.first.component, log.generateReport(isWinner: true));
    }

    // 2. Identify Main Declaration
    final mainNode = _findMainDeclaration(unit.unit, filePath);
    final element = mainNode?.declaredFragment?.element;
    final className = element?.name;

    final headerLog = StringBuffer();
    headerLog.writeln(
        '   (Refiner Analyzed Node: "${className ?? 'Unknown'}" [${mainNode.runtimeType}])');

    final logs = <ScoreLog>[];

    for (final candidate in candidates) {
      final log = ScoreLog(candidate);
      final cConfig = candidate.component;

      // [0] PATH & MODE
      final pathScore = (candidate.matchIndex * 10.0) + candidate.matchLength;
      log.add(pathScore,
          'PATH: Idx:${candidate.matchIndex}, Len:${candidate.matchLength}');

      if (cConfig.mode == ComponentMode.file) {
        log.add(50, 'MODE: File');
      } else if (cConfig.mode == ComponentMode.part) {
        log.add(-50, 'MODE: Part');
      }

      // [1] NAMING PATTERN
      if (cConfig.patterns.isNotEmpty && className != null) {
        bool matchesPattern = false;
        String matchedPattern = '';
        for (final p in cConfig.patterns) {
          if (validateName(className, p)) {
            matchesPattern = true;
            matchedPattern = p;
            break;
          }
        }

        if (matchesPattern) {
          log.add(40.0 + matchedPattern.length,
              'NAME: Matched "$matchedPattern"');
        } else {
          log.add(-5, 'NAME: No match for ${cConfig.patterns}');
        }
      }

      // [1.5] CONVENTION HEURISTIC
      if (className != null) {
        final idLower = cConfig.id.toLowerCase();
        final nameLower = className.toLowerCase();

        final isImplComponent =
            idLower.contains('impl') || idLower.contains('implementation');
        final isImplClass = nameLower.endsWith('impl');

        if (isImplComponent && isImplClass) {
          log.add(60, 'CONV: Impl/Impl Match');
        }
        if (!isImplComponent && isImplClass) {
          log.add(-20, 'CONV: Impl class in Non-Impl Comp');
        }
      }

      // [2] INHERITANCE
      if (element is InterfaceElement) {
        final inheritanceRules = config.inheritances.where(
              (r) => r.onIds.contains(cConfig.id),
        );

        for (final rule in inheritanceRules) {
          if (rule.required.isNotEmpty) {
            if (satisfiesRule(element, rule, config, fileResolver)) {
              final requiresComponent =
              rule.required.any((d) => d.component != null);
              log.add(requiresComponent ? 80 : 40, 'INHERIT: Requirement Met');
            } else {
              log.add(-30, 'INHERIT: Requirement Failed');
            }
          }
        }

        if (_checkSiblingInheritance(element, candidate, candidates)) {
          log.add(50, 'SIBLING: Implements Sibling');
        }
      }

      // [3] STRUCTURE
      if (mainNode != null) {
        if (cConfig.kinds.isNotEmpty) {
          final actualKind = _identifyKind(mainNode);
          if (actualKind != null && cConfig.kinds.contains(actualKind)) {
            log.add(20, 'KIND: Matched ${actualKind.name}');
          } else {
            final req = cConfig.kinds.map((k) => k.name).join(',');
            log.add(-200,
                'KIND: Mismatch (Found:${actualKind?.name}, Req:[$req])');
          }
        }

        if (cConfig.modifiers.isNotEmpty && mainNode is ClassDeclaration) {
          if (_checkModifiers(mainNode, cConfig.modifiers)) {
            log.add(20, 'MODS: Matched');
          } else {
            final req = cConfig.modifiers.map((m) => m.name).join(',');
            log.add(-200, 'MODS: Mismatch (Req:[$req])');
          }
        }
      }

      // [4] TIE BREAKER
      final tie = cConfig.id.split('.').length * 0.1;
      log.add(tie, 'TIE: Depth');

      logs.add(log);
    }

    _calculateConfidence(logs);
    logs.sort();

    final winner = logs.first;

    final fullReport = StringBuffer();
    fullReport.writeln(headerLog.toString().trim());
    fullReport.writeln('');
    fullReport
        .write(logs.map((l) => l.generateReport(isWinner: l == winner)).join('\n'));

    return _buildContext(
      filePath,
      winner.candidate.component,
      fullReport.toString(),
    );
  }

  /// Calculates confidence as a percentage of the Winner's score.
  /// This prevents valid path matches (high base score) from showing as 0%.
  void _calculateConfidence(List<ScoreLog> logs) {
    if (logs.isEmpty) return;

    var maxScore = -double.infinity;
    for (final l in logs) {
      if (l.totalScore > maxScore) maxScore = l.totalScore;
    }

    // Safety: If max score is 0 or negative, we handle it gracefully
    if (maxScore <= 0) maxScore = 1.0;

    for (final log in logs) {
      // Ratio: How close is this score to the winner?
      // e.g. Winner 1388, Current 1023 -> 0.73 (73%)
      final ratio = log.totalScore / maxScore;
      log.confidence = ratio.clamp(0.0, 1.0);
    }
  }

  // --- Helpers ---

  NamedCompilationUnitMember? _findMainDeclaration(
      CompilationUnit unit, String filePath) {
    final filename = p.basenameWithoutExtension(filePath);
    final expectedName = filename.toPascalCase();
    NamedCompilationUnitMember? firstPublicClass;
    NamedCompilationUnitMember? firstPublic;

    for (final declaration in unit.declarations) {
      if (declaration is! NamedCompilationUnitMember) continue;
      final name = declaration.name.lexeme;
      if (name == expectedName) return declaration;
      if (!name.startsWith('_')) {
        if (firstPublic == null) firstPublic = declaration;
        if (firstPublicClass == null && declaration is ClassDeclaration) {
          firstPublicClass = declaration;
        }
      }
    }
    return firstPublicClass ??
        firstPublic ??
        (unit.declarations.whereType<NamedCompilationUnitMember>().firstOrNull);
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

  bool _checkModifiers(
      ClassDeclaration node, List<ComponentModifier> requiredModifiers) {
    final element = node.declaredFragment?.element;
    if (element == null) return false;
    for (final mod in requiredModifiers) {
      switch (mod) {
        case ComponentModifier.abstract:
          if (!element.isAbstract &&
              !element.isInterface &&
              !element.isMixinClass) return false;
          break;
        case ComponentModifier.sealed:
          if (!element.isSealed) return false;
          break;
        case ComponentModifier.base:
          if (!element.isBase) return false;
          break;
        case ComponentModifier.interface:
          if (!element.isInterface) return false;
          break;
        case ComponentModifier.final$:
          if (!element.isFinal) return false;
          break;
        case ComponentModifier.mixin:
          if (!element.isMixinClass) return false;
          break;
      }
    }
    return true;
  }

  bool _checkSiblingInheritance(InterfaceElement element, Candidate current,
      List<Candidate> allCandidates) {
    final supertypes = element.allSupertypes;
    for (final supertype in supertypes) {
      final superElement = supertype.element;
      final library = superElement.library;
      if (library == null) continue;

      final sourcePath = library.firstFragment.source.fullName;
      final superComponent = fileResolver.resolve(sourcePath);

      if (superComponent == null) continue;

      final isSibling =
      allCandidates.any((c) => c.component.id == superComponent.id);

      if (isSibling && superComponent.id != current.component.id) {
        if (current.component.id.length > superComponent.id.length) return true;
        if (current.component.id.toLowerCase().contains('impl') &&
            !superComponent.id.toLowerCase().contains('impl')) return true;
      }
    }
    return false;
  }

  ComponentContext _buildContext(String filePath, ComponentConfig config,
      [String? log]) {
    return ComponentContext(
      filePath: filePath,
      config: config,
      module: fileResolver.resolveModule(filePath),
      debugScoreLog: log,
    );
  }
}