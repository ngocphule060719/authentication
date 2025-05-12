import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:authentication/auth/data/datasources/auth_local_data_source.dart';
import 'package:authentication/auth/data/datasources/auth_remote_data_source.dart';
import 'package:authentication/auth/data/repositories/auth_repository_impl.dart';
import 'package:authentication/auth/domain/models/auth_result.dart';
import 'package:authentication/auth/domain/models/user.dart';
import 'package:authentication/auth/domain/exceptions/auth_exceptions.dart';
import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([AuthLocalDataSource, AuthRemoteDataSource])
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockLocalDataSource = MockAuthLocalDataSource();
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  const testUser = User(
    id: '1',
    email: 'test@example.com',
    name: 'Test User',
  );

  const testAuthResult = AuthResult(
    user: testUser,
    token: 'test_token',
  );

  group('login', () {
    test('should return AuthResult when login is successful', () async {
      // Arrange
      when(mockRemoteDataSource.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => testAuthResult);

      when(mockLocalDataSource.saveToken(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result, equals(testAuthResult));
      verify(mockLocalDataSource.saveToken(testAuthResult.token)).called(1);
    });

    test('should throw AuthException when login fails', () async {
      // Arrange
      when(mockRemoteDataSource.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(const AuthException('Invalid credentials'));

      // Act & Assert
      expect(
        () => repository.login(
          email: 'test@example.com',
          password: 'wrong_password',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('should throw StorageException when saving token fails', () async {
      // Arrange
      when(mockRemoteDataSource.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => testAuthResult);

      when(mockLocalDataSource.saveToken(any))
          .thenThrow(StorageException('Failed to save token'));

      // Act & Assert
      expect(
        () => repository.login(
          email: 'test@example.com',
          password: 'password123',
        ),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('register', () {
    test('should return AuthResult when registration is successful', () async {
      // Arrange
      when(mockRemoteDataSource.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      )).thenAnswer((_) async => testAuthResult);

      when(mockLocalDataSource.saveToken(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.register(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      );

      // Assert
      expect(result, equals(testAuthResult));
      verify(mockLocalDataSource.saveToken(testAuthResult.token)).called(1);
    });

    test('should throw AuthException when registration fails', () async {
      // Arrange
      when(mockRemoteDataSource.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      )).thenThrow(const AuthException('Email already exists'));

      // Act & Assert
      expect(
        () => repository.register(
          email: 'existing@example.com',
          password: 'password123',
          name: 'Test User',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test(
        'should throw StorageException when saving token fails after successful registration',
        () async {
      // Arrange
      when(mockRemoteDataSource.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      )).thenAnswer((_) async => testAuthResult);

      when(mockLocalDataSource.saveToken(any))
          .thenThrow(StorageException('Failed to save token'));

      // Act & Assert
      expect(
        () => repository.register(
          email: 'test@example.com',
          password: 'password123',
          name: 'Test User',
        ),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('requestPasswordReset', () {
    test('should complete successfully when email is valid', () async {
      // Arrange
      when(mockRemoteDataSource.requestPasswordReset(
        email: anyNamed('email'),
      )).thenAnswer((_) async {});

      // Act & Assert
      await expectLater(
        repository.requestPasswordReset(email: 'test@example.com'),
        completes,
      );

      verify(mockRemoteDataSource.requestPasswordReset(
        email: 'test@example.com',
      )).called(1);
    });

    test('should throw AuthException when email is invalid', () async {
      // Arrange
      when(mockRemoteDataSource.requestPasswordReset(
        email: anyNamed('email'),
      )).thenThrow(const AuthException('Invalid email'));

      // Act & Assert
      expect(
        () => repository.requestPasswordReset(email: 'invalid-email'),
        throwsA(isA<AuthException>()),
      );
    });

    test('should throw AuthException when user not found', () async {
      // Arrange
      when(mockRemoteDataSource.requestPasswordReset(
        email: anyNamed('email'),
      )).thenThrow(const AuthException('User not found'));

      // Act & Assert
      expect(
        () => repository.requestPasswordReset(email: 'nonexistent@example.com'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('token management', () {
    test('should return token when it exists', () async {
      // Arrange
      const token = 'test_token';
      when(mockLocalDataSource.getToken()).thenAnswer((_) async => token);

      // Act
      final result = await repository.getToken();

      // Assert
      expect(result, equals(token));
    });

    test('should return null when token does not exist', () async {
      // Arrange
      when(mockLocalDataSource.getToken()).thenAnswer((_) async => null);

      // Act
      final result = await repository.getToken();

      // Assert
      expect(result, isNull);
    });

    test('should save token successfully', () async {
      // Arrange
      const token = 'new_test_token';
      when(mockLocalDataSource.saveToken(any)).thenAnswer((_) async {});

      // Act
      await repository.saveToken(token);

      // Assert
      verify(mockLocalDataSource.saveToken(token)).called(1);
    });

    test('should throw StorageException when saving token fails', () async {
      // Arrange
      const token = 'new_test_token';
      when(mockLocalDataSource.saveToken(any))
          .thenThrow(StorageException('Failed to save token'));

      // Act & Assert
      expect(
        () => repository.saveToken(token),
        throwsA(isA<StorageException>()),
      );
    });

    test('should clear token on logout', () async {
      // Arrange
      when(mockLocalDataSource.deleteToken()).thenAnswer((_) async {});

      // Act
      await repository.logout();

      // Assert
      verify(mockLocalDataSource.deleteToken()).called(1);
    });

    test('should throw StorageException when clearing token fails', () async {
      // Arrange
      when(mockLocalDataSource.deleteToken())
          .thenThrow(StorageException('Failed to clear token'));

      // Act & Assert
      expect(
        () => repository.logout(),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('isAuthenticated', () {
    setUp(() {
      when(mockLocalDataSource.hasToken()).thenAnswer((_) async => true);
    });

    test('should return true when token exists', () async {
      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, isTrue);
      verify(mockLocalDataSource.hasToken()).called(1);
    });

    test('should return false when token does not exist', () async {
      // Arrange
      when(mockLocalDataSource.hasToken()).thenAnswer((_) async => false);

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, isFalse);
      verify(mockLocalDataSource.hasToken()).called(1);
    });

    test('should return false when getting token throws error', () async {
      // Arrange
      when(mockLocalDataSource.hasToken())
          .thenThrow(StorageException('Failed to check token'));

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, isFalse);
      verify(mockLocalDataSource.hasToken()).called(1);
    });
  });
}
