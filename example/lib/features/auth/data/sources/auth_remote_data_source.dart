
import 'package:example/features/auth/data/models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel> getUser(int id);
}

class DefaultAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> getUser(int id) async {
    await Future.delayed.call(const Duration(seconds: 1));
    return UserModel(id: '$id', name: 'Correct User (from API)');
  }
}
