import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:authentication/auth/domain/exceptions/auth_exceptions.dart';
import 'package:authentication/auth/domain/models/user_credentials.dart';

class SecureStorageService {
  final FlutterSecureStorage storage;
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'user_email';
  static const String _userIdKey = 'user_id';
  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

  SecureStorageService({required this.storage});

  bool _isValidData(String value) {
    if (value.contains('\x00')) {
      return false;
    }

    if (value.toLowerCase().contains("drop table") ||
        value.toLowerCase().contains("delete from") ||
        (value.contains("'") && value.contains("--") && value.contains(";"))) {
      return false;
    }
    return true;
  }

  bool _isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }

  Future<void> saveToken(String token) async {
    try {
      if (token.isEmpty) {
        throw StorageException('Token cannot be empty');
      }
      if (!_isValidData(token)) {
        throw StorageException('Invalid token format');
      }
      await storage.write(key: _tokenKey, value: token);
    } catch (e) {
      if (e is StorageException) {
        rethrow;
      }
      throw StorageException('Failed to save token: ${e.toString()}');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await storage.read(key: _tokenKey);
      if (token == null) {
        return null;
      }
      if (!_isValidData(token)) {
        throw StorageException('Corrupted token data');
      }
      return token;
    } catch (e) {
      if (e is StorageException) {
        rethrow;
      }
      throw StorageException('Failed to get token: ${e.toString()}');
    }
  }

  Future<void> deleteToken() async {
    try {
      await storage.delete(key: _tokenKey);
    } catch (e) {
      throw StorageException('Failed to delete token: ${e.toString()}');
    }
  }

  Future<void> saveUserCredentials({
    required String email,
    required String userId,
  }) async {
    try {
      if (!_isValidData(email) || !_isValidData(userId)) {
        throw StorageException('Invalid data format');
      }
      if (!_isValidEmail(email)) {
        throw StorageException('Invalid email format');
      }
      await Future.wait([
        storage.write(key: _emailKey, value: email),
        storage.write(key: _userIdKey, value: userId),
      ]);
    } catch (e) {
      if (e is StorageException) {
        rethrow;
      }
      throw StorageException(
          'Failed to save user credentials: ${e.toString()}');
    }
  }

  Future<UserCredentials?> getUserCredentials() async {
    try {
      final email = await storage.read(key: _emailKey);
      final userId = await storage.read(key: _userIdKey);

      if (email == null || userId == null) {
        return null;
      }

      if (!_isValidData(email) || !_isValidData(userId)) {
        throw StorageException('Corrupted user credentials');
      }

      return UserCredentials(
        email: email,
        userId: userId,
      );
    } catch (e) {
      if (e is StorageException) {
        rethrow;
      }
      throw StorageException('Failed to get user credentials: ${e.toString()}');
    }
  }

  Future<void> clearUserData() async {
    var errors = <String>[];

    try {
      await storage.delete(key: _emailKey);
    } catch (e) {
      errors.add('email');
    }

    try {
      await storage.delete(key: _userIdKey);
    } catch (e) {
      errors.add('userId');
    }

    try {
      await storage.delete(key: _tokenKey);
    } catch (e) {
      errors.add('token');
    }

    if (errors.isNotEmpty) {
      throw StorageException('Failed to clear: ${errors.join(", ")}');
    }
  }

  Future<void> clearAllData() async {
    try {
      await storage.deleteAll();
    } catch (e) {
      throw StorageException('Failed to clear all data: ${e.toString()}');
    }
  }
}
