// example/lib/features/auth/data/sources/default_auth_source.dart

import 'package:example/core/error/exceptions.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/data/models/user_model.dart';
import 'package:example/features/auth/data/sources/auth_source.dart';

// CORRECT:
// 1. Name matches `Default{{name}}Source`.
// 2. Implements the specific interface `AuthSource`.
class DefaultAuthSource implements AuthSource {

  @override
  Future<UserModel> getUser(StringId id) async {
    // CORRECT: Error Handling
    // DataSources are "Producers". They throw Exceptions, they do NOT return Failures.
    if (id.isEmpty) {
      throw ServerException();
    }

    // Simulate API call
    await Future.delayed.call(const Duration(milliseconds: 100));

    return UserModel(id: id, username: 'User');
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    // ... implementation
  }
}