import 'package:flutter_test/flutter_test.dart';
import 'package:authentication/auth/data/datasources/auth_remote_data_source.dart';
import 'package:authentication/auth/data/datasources/implementations/auth_remote_data_source_impl.dart';
import 'package:authentication/auth/domain/exceptions/auth_exceptions.dart';

void main() {
  late AuthRemoteDataSource remoteDataSource;

  setUp(() {
    remoteDataSource = AuthRemoteDataSourceImpl();
  });

  group('login', () {
    test('should return AuthResult on successful login', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'valid_password';

      // Act
      final result = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Assert
      expect(result.user.email, equals(email));
      expect(result.user.name, equals('Test User'));
      expect(result.token, isNotEmpty);
    });

    test('should throw AuthException with invalid credentials', () async {
      // Arrange
      const email = 'wrong@example.com';
      const password = 'wrong_password';

      // Act & Assert
      expect(
        () => remoteDataSource.login(
          email: email,
          password: password,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('should throw AuthException with empty password', () async {
      // Arrange
      const email = 'test@example.com';
      const password = '';

      // Act & Assert
      expect(
        () => remoteDataSource.login(
          email: email,
          password: password,
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('register', () {
    test('should return AuthResult on successful registration', () async {
      // Arrange
      const email = 'new@example.com';
      const password = 'valid_password';
      const name = 'New User';

      // Act
      final result = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
      );

      // Assert
      expect(result.user.email, equals(email));
      expect(result.user.name, equals(name));
      expect(result.token, isNotEmpty);
    });

    test('should throw AuthException with existing email', () async {
      // Arrange
      const email = 'existing@example.com';
      const password = 'valid_password';
      const name = 'Test User';

      // Act & Assert
      expect(
        () => remoteDataSource.register(
          email: email,
          password: password,
          name: name,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('should throw AuthException with empty name', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'valid_password';
      const name = '';

      // Act & Assert
      expect(
        () => remoteDataSource.register(
          email: email,
          password: password,
          name: name,
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('requestPasswordReset', () {
    test('should complete successfully with valid email', () async {
      // Arrange
      const email = 'test@example.com';

      // Act & Assert
      expect(
        remoteDataSource.requestPasswordReset(email: email),
        completes,
      );
    });

    test('should throw AuthException with invalid email format', () async {
      // Arrange
      const email = 'invalid-email';

      // Act & Assert
      expect(
        () => remoteDataSource.requestPasswordReset(email: email),
        throwsA(isA<AuthException>()),
      );
    });

    test('should throw AuthException with non-existent email', () async {
      // Arrange
      const email = 'invalid@example.com';

      // Act & Assert
      expect(
        () => remoteDataSource.requestPasswordReset(email: email),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
