// test/src/analysis/naming_strategy_test.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/configs/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('NamingStrategy', () {
    late NamingStrategy strategy;

    setUp(() {
      // specific rules vs generic rules
      final rules = [
        // Specific: Length 13 ({{name}}Model)
        const NamingRule(on: ['model'], pattern: '{{name}}Model'),
        // Specific: Length 12 ({{name}}Port)
        const NamingRule(on: ['port'], pattern: '{{name}}Port'),
        // Generic: Length 8 ({{name}})
        const NamingRule(on: ['entity'], pattern: '{{name}}'),
        // Another Generic: Length 8 ({{name}})
        const NamingRule(on: ['usecase'], pattern: '{{name}}'),
      ];

      strategy = NamingStrategy(rules);
    });

    test('should NOT yield if class name matches the current component pattern', () {
      // Scenario: 'UserModel' inside 'models' directory.
      // It matches the Model pattern perfectly.
      expect(
        strategy.shouldYieldToLocationLint('UserModel', ArchComponent.model, null),
        isFalse,
        reason: 'Name is syntactically correct for the location.',
      );
    });

    test('should NOT yield if class name matches NO known patterns', () {
      // Scenario: 'user_model' (snake_case) inside 'models' directory.
      // It doesn't match Model, Entity, or Port patterns (PascalCase required).
      // The Naming Lint should handle this (by reporting an error), not the Location Lint.
      expect(
        strategy.shouldYieldToLocationLint('user_model', ArchComponent.model, null),
        isFalse,
        reason: 'Garbage name should be flagged by naming lint, not yielded.',
      );
    });

    test('should YIELD if name matches a DIFFERENT component pattern specifically', () {
      // Scenario: 'UserPort' inside 'models' directory.
      // - Current (Model): Expects {{name}}Model. 'UserPort' does NOT match.
      // - Other (Port): Expects {{name}}Port. 'UserPort' MATCHES.
      // Result: This file likely belongs in the Port directory. Yield to Location Lint.
      expect(
        strategy.shouldYieldToLocationLint('UserPort', ArchComponent.model, null),
        isTrue,
        reason: 'Class name strongly indicates it belongs to another component.',
      );
    });

    test('should YIELD if name matches a GENERIC pattern in a SPECIFIC folder', () {
      // Scenario: 'User' (Entity style) inside 'models' directory.
      // - Current (Model): Expects {{name}}Model. 'User' does NOT match.
      // - Other (Entity): Expects {{name}}. 'User' MATCHES.
      // Result: Likely an Entity placed in the Model folder.
      expect(
        strategy.shouldYieldToLocationLint('User', ArchComponent.model, null),
        isTrue,
      );
    });

    test('should NOT yield if name is AMBIGUOUS (matches current and others)', () {
      // Scenario: 'Login' inside 'usecases' directory.
      // - Current (UseCase): Expects {{name}}. 'Login' MATCHES.
      // - Other (Entity): Expects {{name}}. 'Login' MATCHES.
      // Since it fits the current location, we assume it's correct.
      expect(
        strategy.shouldYieldToLocationLint('Login', ArchComponent.usecase, null),
        isFalse,
        reason: 'If valid for current location, do not yield even if it matches others.',
      );
    });

    test('should NOT yield if STRUCTURAL IDENTITY confirms the component', () {
      // Scenario: 'AuthContract' inside 'ports' directory.
      // - Name: 'AuthContract'.
      // - Current (Port): Expects {{name}}Port. 'AuthContract' does NOT match.
      // - Best Guess: Entity ({{name}}).
      // - Structural: It implements `Port` interface (passed as arg).

      // Because we know via inheritance that it IS a Port, we stay here.
      // This allows the Naming Lint to report "Name should end in Port",
      // instead of the Location Lint reporting "Entity found in Port directory".
      expect(
        strategy.shouldYieldToLocationLint('AuthContract', ArchComponent.port, ArchComponent.port),
        isFalse,
        reason: 'Inheritance overrides naming guess.',
      );
    });
  });
}
