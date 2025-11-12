// test/src/utils/extensions/iterable_extension_test.dart

import 'package:clean_architecture_kit/src/utils/extensions/iterable_extension.dart';
import 'package:test/test.dart';

void main() {
  group('IterableExtension', () {
    group('firstWhereOrNull', () {
      final numbers = [10, 25, 30, 45, 50];

      test('should return the first element that satisfies the predicate', () {
        // Find the first number greater than 40.
        final result = numbers.firstWhereOrNull((n) => n > 40);
        expect(result, 45);
      });

      test('should return the very first element if it satisfies the predicate', () {
        final result = numbers.firstWhereOrNull((n) => n == 10);
        expect(result, 10);
      });

      test('should return the last element if only it satisfies the predicate', () {
        final result = numbers.firstWhereOrNull((n) => n == 50);
        expect(result, 50);
      });

      test('should return null if no element satisfies the predicate', () {
        // Find the first number greater than 100.
        final result = numbers.firstWhereOrNull((n) => n > 100);
        expect(result, isNull);
      });

      test('should return null for an empty list', () {
        final emptyList = <int>[];
        final result = emptyList.firstWhereOrNull((n) => n > 0);
        expect(result, isNull);
      });

      test('should work with lists of objects', () {
        final users = [
          const _User(1, 'Alice'),
          const _User(2, 'Bob'),
          const _User(3, 'Charlie'),
        ];

        final result = users.firstWhereOrNull((user) => user.name == 'Bob');
        expect(result, isNotNull);
        expect(result?.id, 2);
      });

      test('should return null if no object is found', () {
        final users = [const _User(1, 'Alice')];
        final result = users.firstWhereOrNull((user) => user.name == 'David');
        expect(result, isNull);
      });
    });
  });
}

// A simple helper class for object tests.
class _User {
  final int id;
  final String name;
  const _User(this.id, this.name);
}
