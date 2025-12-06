// example/lib/features/auth/data/sources/default_auth_source.dart

import 'package:clean_feature_first/core/error/exceptions.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/data/models/user_model.dart';
import 'package:clean_feature_first/features/auth/data/sources/auth_source.dart';

// Wrong: arch_type_missing_base
// Warning: The component "Data Source (Interface)" is invalid. It must extend or implement: Source.
//
// Extend or implement one of the required types.
class DefaultAuthSource implements AuthSource {

  @override
  Future<UserModel> getUser(StringId id) async {

    if (id.isEmpty) {
      throw ServerException();
    }

    // Simulate API call
    await Future.delayed.call(const Duration(milliseconds: 100));

    return UserModel(id: id, name: 'User');
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    // ... implementation
  }
}