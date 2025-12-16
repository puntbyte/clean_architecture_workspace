import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:architecture_lints/src/schema/enums/component_kind.dart';
import 'package:architecture_lints/src/schema/enums/component_mode.dart';
import 'package:architecture_lints/src/schema/enums/component_modifier.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:architecture_lints/src/schema/policies/inheritance_policy.dart';
import 'package:architecture_lints/src/engines/component/component_refiner.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class MockFileResolver extends Mock implements FileResolver {}

void main() {
  group('ComponentRefiner (The Brain)', () {
    late Directory tempDir;
    late MockFileResolver mockResolver;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('refiner_test_');
      mockResolver = MockFileResolver();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    // --- Helpers ---

    Future<ResolvedUnitResult> resolveCode(String content) async {
      final file = File(p.join(tempDir.path, 'lib/test.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
      final result = await resolveFile(path: p.normalize(file.absolute.path));
      return result as ResolvedUnitResult;
    }

    Candidate candidate(
      String id, {
      List<String> paths = const [],
      List<String> patterns = const [],
      List<ComponentKind> kinds = const [],
      List<ComponentModifier> modifiers = const [],
      ComponentMode mode = ComponentMode.file,
      int matchIndex = 0,
      int matchLength = 10,
    }) {
      return Candidate(
        // FIX: Use named parameters
        component: ComponentDefinition(
          id: id,
          paths: paths,
          patterns: patterns,
          kinds: kinds,
          modifiers: modifiers,
          mode: mode,
        ),
        matchLength: matchLength,
        matchIndex: matchIndex,
      );
    }

    // --- Tests ---

    test('should prioritize Mode: File over Mode: Part', () async {
      // Scenario: A file vs a part defined in the same folder.
      // E.g. 'UserBloc' (File) vs 'UserEvent' (Part of Bloc).
      final candidates = [
        candidate('bloc.event', mode: ComponentMode.part, patterns: ['{{name}}']),
        // Generic pattern
        candidate('bloc.main', mode: ComponentMode.file, patterns: ['{{name}}Bloc']),
      ];

      when(() => mockResolver.resolveAllCandidates(any())).thenReturn(candidates);
      when(() => mockResolver.resolveModule(any())).thenReturn(null);

      final unit = await resolveCode('class UserBloc {}');
      final refiner = ComponentRefiner(ArchitectureConfig.empty(), mockResolver);

      final result = refiner.refine(filePath: 'user_bloc.dart', unit: unit);

      // File mode gets +50, Part mode gets -50. File wins easily.
      expect(result?.id, 'bloc.main');
    });

    test('should prioritize Specific Path Match over Generic', () async {
      // Scenario: 'domain' vs 'domain.model'.
      final candidates = [
        candidate('domain', matchLength: 6, matchIndex: 0),
        candidate('domain.model', matchLength: 12, matchIndex: 0),
      ];

      when(() => mockResolver.resolveAllCandidates(any())).thenReturn(candidates);
      when(() => mockResolver.resolveModule(any())).thenReturn(null);

      final unit = await resolveCode('class User {}');
      final refiner = ComponentRefiner(ArchitectureConfig.empty(), mockResolver);

      final result = refiner.refine(filePath: 'user.dart', unit: unit);

      // Deeper path length wins (12 > 6)
      expect(result?.id, 'domain.model');
    });

    test('should prioritize Correct Structure (Abstract vs Concrete)', () async {
      // Scenario: Interface vs Implementation in same folder.
      final cInterface = candidate(
        'source.interface',
        modifiers: [ComponentModifier.abstract], // Must be abstract
      );
      final cImpl = candidate(
        'source.implementation',
        modifiers: [], // Can be concrete
      );

      when(() => mockResolver.resolveAllCandidates(any())).thenReturn([cInterface, cImpl]);
      when(() => mockResolver.resolveModule(any())).thenReturn(null);

      final refiner = ComponentRefiner(ArchitectureConfig.empty(), mockResolver);

      // Case A: Concrete Class -> Should resolve to Implementation
      final concreteUnit = await resolveCode('class AuthSourceImpl {}');
      final resConcrete = refiner.refine(filePath: 'file.dart', unit: concreteUnit);

      // Interface gets -200 penalty for being concrete. Implementation wins.
      expect(resConcrete?.id, 'source.implementation');

      // Case B: Abstract Class -> Should resolve to Interface
      final abstractUnit = await resolveCode('abstract class AuthSource {}');
      final resAbstract = refiner.refine(filePath: 'file.dart', unit: abstractUnit);

      // Interface gets +20 bonus. Implementation gets neutral/lower.
      expect(resAbstract?.id, 'source.interface');
    });

    test('should prioritize Naming Pattern Match', () async {
      final cEntity = candidate('entity', patterns: ['{{name}}Entity']);
      final cModel = candidate('model', patterns: ['{{name}}Model']);

      when(() => mockResolver.resolveAllCandidates(any())).thenReturn([cEntity, cModel]);
      when(() => mockResolver.resolveModule(any())).thenReturn(null);

      final unit = await resolveCode('class UserModel {}');
      final refiner = ComponentRefiner(ArchitectureConfig.empty(), mockResolver);

      final result = refiner.refine(filePath: 'file.dart', unit: unit);

      // Model pattern matches (+40). Entity pattern fails (-5).
      expect(result?.id, 'model');
    });

    test('should handle The "AuthSourceImpl" Grand Scenario', () async {
      // This tests the interaction of Inheritance, Convention, and Structure.

      // 1. Interface: Requires abstract.
      final cInterface = candidate(
        'data.source.interface',
        patterns: ['{{name}}Source'],
        modifiers: [ComponentModifier.abstract],
      );

      // 2. Implementation: Requires sibling inheritance + 'Impl' convention.
      final cImpl = candidate(
        'data.source.implementation',
        patterns: ['{{affix}}{{name}}Source'], // Doesn't match 'AuthSourceImpl'
      );

      final config = ArchitectureConfig(
        components: [cInterface.component, cImpl.component],
        inheritances: [
          const InheritancePolicy(
            onIds: ['data.source.implementation'],
            required: [TypeDefinition(component: 'data.source.interface')],
            allowed: [],
            forbidden: [],
          ),
        ],
      );

      when(() => mockResolver.resolveAllCandidates(any())).thenReturn([cInterface, cImpl]);
      when(() => mockResolver.resolveModule(any())).thenReturn(null);

      // Mock the inheritance lookup: 'AuthSource' -> 'data.source.interface'
      when(() => mockResolver.resolve(any())).thenAnswer((_) {
        return ComponentContext(
          filePath: 'auth_source.dart',
          definition: cInterface.component,
        );
      });

      // THE CODE: Concrete class ending in 'Impl', implementing the interface.
      final unit = await resolveCode('''
        abstract class AuthSource {} 
        class AuthSourceImpl implements AuthSource {}
      ''');

      final refiner = ComponentRefiner(config, mockResolver);
      final result = refiner.refine(filePath: 'auth_source_impl.dart', unit: unit);

      // SCORING PREDICTION:
      // Interface:
      // - Structure: Concrete class (-200). Disqualified.
      //
      // Implementation:
      // - Structure: Concrete (Neutral/Positive).
      // - Inheritance: Implements AuthSource (interface) -> (+80).
      // - Convention: 'Impl' suffix match (+60).
      // - Naming: 'AuthSourceImpl' vs '...Source' pattern (-5).
      //
      // Winner: Implementation (by a huge margin).
      expect(result?.id, 'data.source.implementation');
    });

    test('should fallback to ID depth if everything else is equal', () async {
      // e.g. 'source' vs 'source.sub'. Both match path and naming.
      final cParent = candidate('source', matchLength: 5);
      final cChild = candidate('source.sub', matchLength: 5);

      when(() => mockResolver.resolveAllCandidates(any())).thenReturn([cParent, cChild]);
      when(() => mockResolver.resolveModule(any())).thenReturn(null);

      final unit = await resolveCode('class Anything {}');
      final refiner = ComponentRefiner(ArchitectureConfig.empty(), mockResolver);

      final result = refiner.refine(filePath: 'file.dart', unit: unit);

      // Child has longer ID, so it wins the tie-breaker.
      expect(result?.id, 'source.sub');
    });
  });
}
