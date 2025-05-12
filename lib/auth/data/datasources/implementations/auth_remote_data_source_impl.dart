import 'package:authentication/auth/domain/models/auth_result.dart';
import 'package:authentication/auth/domain/exceptions/auth_exceptions.dart';
import 'package:authentication/auth/domain/models/user.dart';
import '../auth_remote_data_source.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // Mock implementation for testing
    if (email == 'test@example.com' && password.isNotEmpty) {
      return AuthResult(
        user: User(
          id: '1',
          email: email,
          name: 'Test User',
        ),
        token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    throw const AuthException('Invalid credentials');
  }

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
  }) async {
    // Mock implementation for testing
    if (email == 'existing@example.com') {
      throw const AuthException('Email already exists');
    }

    if (name.trim().isEmpty) {
      throw const AuthException('Name cannot be empty');
    }

    return AuthResult(
      user: User(
        id: '2',
        email: email,
        name: name,
      ),
      token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    if (email.isEmpty || !email.contains('@')) {
      throw const AuthException('Invalid email format');
    }

    if (email == 'invalid@example.com') {
      throw const AuthException('User not found');
    }

    // Mock successful password reset request
    return;
  }
}
