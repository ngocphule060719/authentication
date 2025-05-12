import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:authentication/auth/data/datasources/auth_local_data_source.dart';
import 'package:authentication/auth/data/datasources/implementations/auth_local_data_source_impl.dart';
import 'package:authentication/auth/domain/exceptions/auth_exceptions.dart';
import 'auth_local_data_source_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  late AuthLocalDataSource localDataSource;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    localDataSource = AuthLocalDataSourceImpl(secureStorage: mockSecureStorage);
  });

  group('getToken', () {
    test('should return token when it exists in storage', () async {
      // Arrange
      const token = 'test_token';
      when(mockSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => token);

      // Act
      final result = await localDataSource.getToken();

      // Assert
      expect(result, equals(token));
      verify(mockSecureStorage.read(key: 'auth_token')).called(1);
    });

    test('should return null when token does not exist', () async {
      // Arrange
      when(mockSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);

      // Act
      final result = await localDataSource.getToken();

      // Assert
      expect(result, isNull);
      verify(mockSecureStorage.read(key: 'auth_token')).called(1);
    });

    test('should throw StorageException when storage operation fails',
        () async {
      // Arrange
      when(mockSecureStorage.read(key: anyNamed('key')))
          .thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(
        () => localDataSource.getToken(),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('saveToken', () {
    test('should save token successfully', () async {
      // Arrange
      const token = 'test_token';
      when(mockSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      // Act
      await localDataSource.saveToken(token);

      // Assert
      verify(mockSecureStorage.write(
        key: 'auth_token',
        value: token,
      )).called(1);
    });

    test('should throw StorageException when save operation fails', () async {
      // Arrange
      const token = 'test_token';
      when(mockSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(
        () => localDataSource.saveToken(token),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('deleteToken', () {
    test('should delete token successfully', () async {
      // Arrange
      when(mockSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async {});

      // Act
      await localDataSource.deleteToken();

      // Assert
      verify(mockSecureStorage.delete(key: 'auth_token')).called(1);
    });

    test('should throw StorageException when delete operation fails', () async {
      // Arrange
      when(mockSecureStorage.delete(key: anyNamed('key')))
          .thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(
        () => localDataSource.deleteToken(),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('hasToken', () {
    test('should return true when token exists and is not empty', () async {
      // Arrange
      const token = 'test_token';
      when(mockSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => token);

      // Act
      final result = await localDataSource.hasToken();

      // Assert
      expect(result, isTrue);
      verify(mockSecureStorage.read(key: 'auth_token')).called(1);
    });

    test('should return false when token does not exist', () async {
      // Arrange
      when(mockSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);

      // Act
      final result = await localDataSource.hasToken();

      // Assert
      expect(result, isFalse);
      verify(mockSecureStorage.read(key: 'auth_token')).called(1);
    });

    test('should return false when token is empty', () async {
      // Arrange
      when(mockSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => '');

      // Act
      final result = await localDataSource.hasToken();

      // Assert
      expect(result, isFalse);
      verify(mockSecureStorage.read(key: 'auth_token')).called(1);
    });

    test('should throw StorageException when check operation fails', () async {
      // Arrange
      when(mockSecureStorage.read(key: anyNamed('key')))
          .thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(
        () => localDataSource.hasToken(),
        throwsA(isA<StorageException>()),
      );
    });
  });
}
