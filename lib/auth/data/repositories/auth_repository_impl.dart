import 'package:authentication/auth/data/datasources/auth_local_data_source.dart';
import 'package:authentication/auth/data/datasources/auth_remote_data_source.dart';
import 'package:authentication/auth/domain/models/auth_result.dart';
import 'package:authentication/auth/domain/models/user.dart';
import 'package:authentication/auth/domain/repositories/auth_repository.dart';
import 'package:authentication/auth/domain/exceptions/auth_exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await localDataSource.hasToken();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    return await localDataSource.getToken();
  }

  @override
  Future<void> saveToken(String token) async {
    await localDataSource.saveToken(token);
  }

  @override
  Future<void> clearToken() async {
    await localDataSource.deleteToken();
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await remoteDataSource.login(
      email: email,
      password: password,
    );
    await saveToken(result.token);
    return result;
  }

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final result = await remoteDataSource.register(
      email: email,
      password: password,
      name: name,
    );
    await saveToken(result.token);
    return result;
  }

  @override
  Future<void> logout() async {
    await clearToken();
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    await remoteDataSource.requestPasswordReset(email: email);
  }

  @override
  Future<User> getCurrentUser() async {
    try {
      // TODO: Implement actual user data retrieval from remote data source
      // Mock implementation for testing
      return const User(
        id: 'placeholder',
        email: 'placeholder@example.com',
        name: 'Placeholder User',
      );
    } catch (e) {
      throw const AuthException('Failed to get current user');
    }
  }
}
