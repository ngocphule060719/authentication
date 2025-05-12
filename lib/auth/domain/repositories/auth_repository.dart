import 'package:authentication/auth/domain/models/auth_result.dart';
import 'package:authentication/auth/domain/models/user.dart';

abstract class AuthRepository {
  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset({
    required String email,
  });

  Future<String?> getToken();

  Future<void> saveToken(String token);

  Future<void> clearToken();

  Future<bool> isAuthenticated();

  Future<void> logout();

  Future<User> getCurrentUser();
}
