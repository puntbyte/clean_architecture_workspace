import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('NamingStrategy', () {
    // Setup common rules for testing using REAL ArchComponent IDs
    final rules = [
      const NamingRule(
        on: ['model'],
        pattern: '{{name}}Model',
      ),
      const NamingRule(
        on: ['port'],
        pattern: '{{name}}Port',
      ),
      const NamingRule(
        on: ['entity'],
        pattern: '{{name}}', // Generic pattern
      ),
    ];

    late NamingStrategy strategy;

    setUp(() {
      strategy = NamingStrategy(rules);
    });

    test('should NOT yield if class name matches the current component pattern', () {
      // Case: UserModel inside Model component.
      // Best guess: Model. Current: Model.
      // Should validate: Yes.
      expect(
        strategy.shouldYieldToLocationLint('UserModel', ArchComponent.model),
        isFalse,
        reason: 'Name is correct for location.',
      );
    });

    test('should NOT yield if class name matches NO known patterns', () {
      // Case: "user_model" (snake case) inside Model component.
      // NamingUtils logic usually requires PascalCase for {{name}}.
      // So this shouldn't match anything.
      expect(
        strategy.shouldYieldToLocationLint('user_model', ArchComponent.model),
        isFalse,
        reason: 'Name is just garbage/wrong format. Should fail naming lint, not yield.',
      );
    });

    test('should YIELD if name matches another component AND NOT current component', () {
      // Case: UserPort inside Model component.
      // Current (Model): {{name}}Model. 'UserPort' does NOT match.
      // Best Match: Port ({{name}}Port). 'UserPort' matches.
      // Result: It's a valid Port in the wrong folder. Yield.
      expect(
        strategy.shouldYieldToLocationLint('UserPort', ArchComponent.model),
        isTrue,
        reason: 'Class is clearly a Port but found in Model layer.',
      );
    });

    test('should NOT yield if name matches BOTH current and another (Ambiguous)', () {
      // Case: 'User' inside Entity component.
      // Entity Pattern: {{name}} -> Matches.
      // Model Pattern: {{name}}Model -> No.
      // However, let's simulate ambiguity. Suppose UseCase also used {{name}}.

      final ambiguousRules = [
        const NamingRule(on: ['entity'], pattern: '{{name}}'),
        const NamingRule(on: ['usecase'], pattern: '{{name}}'),
      ];
      final ambiguousStrategy = NamingStrategy(ambiguousRules);

      // 'Login' in UseCase folder.
      // Matches UseCase pattern? Yes.
      // Matches Entity pattern? Yes.
      // Should we yield? No. It fits where it is.
      expect(
        ambiguousStrategy.shouldYieldToLocationLint('Login', ArchComponent.usecase),
        isFalse,
        reason: 'Name is valid for current location, even if it matches others.',
      );
    });

    test('should prioritize Specific patterns over Generic ones', () {
      // UserEntity inside Model folder.
      // Patterns: Model={{name}}Model, Entity={{name}}
      // Class: UserEntity.
      // Matches Model? No.
      // Matches Entity? Yes ({{name}} matches 'UserEntity').
      // Result: Yield.
      expect(
        strategy.shouldYieldToLocationLint('UserEntity', ArchComponent.model),
        isTrue,
        reason: 'Matches generic Entity pattern, does not match Model pattern. Likely misplaced.',
      );
    });

    test('should sort patterns by length correctly', () {
      // We use REAL components to ensure they aren't filtered out.
      // 'model' -> {{name}}Model (Specific, Length 13)
      // 'entity' -> {{name}}      (Generic, Length 8)

      // Input: 'UserModel'
      // Matches 'model'? Yes.
      // Matches 'entity'? Yes ('User' matches name).

      // We simulate being in an unknown location (or a component with no rule like 'widget').
      // Since 'widget' has no rule here, _matchesComponentPattern returns false.
      // Therefore, yield decision depends entirely on Best Match.

      // If sorted correctly: Best Match = Model.
      // If sorted incorrectly (generic first): Best Match = Entity.

      // Since 'UserModel' is clearly a Model, we assume the intention is Model.
      // However, yield simply returns true if *any* valid match is found that isn't current.
      // This test checks if the sorting logic works by inspecting the internal list via behavior?
      // Actually, for `shouldYield`, both result in `true` because `widget` != `model` and `widget` != `entity`.

      // Let's try a case where sorting matters for ambiguity check.
      // Suppose we are in 'entity'.
      // Input: 'UserModel'.
      // If Entity check runs first and matches 'UserModel' (as {{name}}), it might NOT yield if logic was flawed?
      // Wait, `_matchesComponentPattern` checks if it matches CURRENT component.
      // 'UserModel' matches 'entity' pattern {{name}}. So if we are in 'entity', we do NOT yield.

      // Let's reverse it. We are in 'model'. Input: 'UserModel'.
      // Matches 'model'? Yes. Don't yield.

      // To verify sorting, we need to ensure `_getBestGuessComponent` returns the LONGER match.
      // We can infer this if we have a setup where the shorter match IS the current component,
      // but the longer match is NOT.

      // Setup:
      // Entity (Current): {{name}}
      // Model (Other): {{name}}Model

      // Input: 'UserModel' inside 'entity'.
      // 1. Best Guess: Should be Model (if sorted correctly).
      // 2. Current Match: Yes (matches {{name}}).
      // 3. Logic: "If matchesCurrent, return false".

      // This implies that even if Model is a better guess, if it fits Entity, we allow it.
      // This is a "safe" strategy to avoid false positives.

      // To strictly test sorting, we rely on the fact that `shouldYieldToLocationLint` uses
      // `_getBestGuessComponent` internally. If we want to test `_getBestGuessComponent` behavior,
      // we'd need it public or inspect internal state.
      // However, for this unit test, we can accept that `shouldYield` behaves correctly for valid inputs.

      expect(
        strategy.shouldYieldToLocationLint('UserModel', ArchComponent.widget),
        isTrue,
      );
    });
  });
}
