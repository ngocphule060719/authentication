import 'package:authentication/auth/domain/models/auth_result.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
  });

  Future<void> requestPasswordReset({
    required String email,
  });
}
 