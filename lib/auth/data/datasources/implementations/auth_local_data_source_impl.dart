import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:authentication/auth/domain/exceptions/auth_exceptions.dart';
import '../auth_local_data_source.dart';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;
  static const String _tokenKey = 'auth_token';

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<String?> getToken() async {
    try {
      return await secureStorage.read(key: _tokenKey);
    } catch (e) {
      throw StorageException('Failed to get token: ${e.toString()}');
    }
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      await secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      throw StorageException('Failed to save token: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await secureStorage.delete(key: _tokenKey);
    } catch (e) {
      throw StorageException('Failed to delete token: ${e.toString()}');
    }
  }

  @override
  Future<bool> hasToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      throw StorageException(
          'Failed to check token existence: ${e.toString()}');
    }
  }
}
