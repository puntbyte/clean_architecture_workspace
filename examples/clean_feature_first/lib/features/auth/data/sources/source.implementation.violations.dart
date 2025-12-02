// example/lib/features/auth/data/sources/source.implementation.violations.dart

import 'package:clean_feature_first/core/error/failures.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/data/models/user_model.dart';
import 'package:clean_feature_first/features/auth/data/sources/auth_source.dart';
import 'package:fpdart/fpdart.dart';

// LINT: [1] disallow_flutter_in_domain
// REASON: While this is data layer, flutter is generally discouraged in pure Dart sources
// unless it's a local source using something like SharedPreferences (depends on config).
// (Assuming config blocks it or context implies strictness).
import 'package:flutter/material.dart';

// LINT: [2] enforce_naming_pattern
// REASON: Name must match `Default{{name}}Source` (configured pattern).
// 'AuthSourceImpl' is the standard flutter way, but this config enforces 'Default...'.
class AuthSourceImpl implements AuthSource { // <-- LINT WARNING HERE

  // LINT: [3] enforce_exception_on_data_source
  // REASON: Implementation returns Either/Right. Sources must throw exceptions.
  FutureEither<UserModel> wrongReturnType() async { // <-- LINT WARNING HERE
    return Right(UserModel(id: '1', name: 'Test'));
  }

  @override
  Future<UserModel> getUser(StringId id) async {
    // LINT: [4] enforce_exception_on_data_source (Logic Check)
    // REASON: Sources should act as "Producers". Catching an exception and
    // returning a Failure/null here means the Repository cannot do its job
    // of mapping exceptions.
    try {
      throw Exception('API Error');
    } catch (e) {
      // This mimics returning "Safe" data which is an anti-pattern in Sources.
      throw ServerFailure(); // Throwing a Domain Failure in Data layer is also bad.
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    // LINT: [5] disallow_service_locator
    // REASON: Dependencies (like HTTP client or DB) must be injected.
    // final db = GetIt.I.get<Database>();
  }
}

// LINT: [6] enforce_abstracting_source_implementation
// REASON: Concrete sources must implement an interface, not stand alone.
class OrphanSource { // <-- LINT WARNING HERE
  Future<void> getData() async {}
}