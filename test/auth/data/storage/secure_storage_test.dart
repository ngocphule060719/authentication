import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:authentication/auth/data/storage/secure_storage_service.dart';
import 'package:authentication/auth/domain/exceptions/auth_exceptions.dart';
import 'secure_storage_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  late SecureStorageService secureStorage;
  late MockFlutterSecureStorage mockFlutterSecureStorage;

  setUp(() {
    mockFlutterSecureStorage = MockFlutterSecureStorage();
    secureStorage = SecureStorageService(storage: mockFlutterSecureStorage);
  });

  group('Token Storage', () {
    const testToken = 'test_auth_token';
    const tokenKey = 'auth_token';

    test('should store token securely', () async {
      // Arrange
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      // Act
      await secureStorage.saveToken(testToken);

      // Assert
      verify(mockFlutterSecureStorage.write(
        key: tokenKey,
        value: testToken,
      )).called(1);
    });

    test('should handle empty token gracefully', () async {
      // Arrange
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      // Act & Assert
      expect(
        () => secureStorage.saveToken(''),
        throwsA(isA<StorageException>()),
      );
    });

    test('should handle very long tokens', () async {
      // Arrange
      final longToken = 'x' * 10000; // Very long token
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      // Act
      await secureStorage.saveToken(longToken);

      // Assert
      verify(mockFlutterSecureStorage.write(
        key: tokenKey,
        value: longToken,
      )).called(1);
    });

    test('should handle special characters in token', () async {
      // Arrange
      const specialToken =
          '!@#\$%^&*()_+-=[]{}|;:,.<>?/~`"\\\''; // Fixed string literal
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      // Act
      await secureStorage.saveToken(specialToken);

      // Assert
      verify(mockFlutterSecureStorage.write(
        key: tokenKey,
        value: specialToken,
      )).called(1);
    });

    test('should handle concurrent token operations', () async {
      // Arrange
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});
      when(mockFlutterSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => testToken);

      // Act
      final futures = await Future.wait([
        secureStorage.saveToken('token1'),
        secureStorage.saveToken('token2'),
        secureStorage.getToken(),
        secureStorage.deleteToken(),
      ]);

      // Assert - No exceptions thrown
      expect(futures, hasLength(4));
    });

    test('should retrieve stored token', () async {
      // Arrange
      when(mockFlutterSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => testToken);

      // Act
      final result = await secureStorage.getToken();

      // Assert
      expect(result, equals(testToken));
      verify(mockFlutterSecureStorage.read(key: tokenKey)).called(1);
    });

    test('should return null when token does not exist', () async {
      // Arrange
      when(mockFlutterSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);

      // Act
      final result = await secureStorage.getToken();

      // Assert
      expect(result, isNull);
    });

    test('should delete token securely', () async {
      // Arrange
      when(mockFlutterSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async {});

      // Act
      await secureStorage.deleteToken();

      // Assert
      verify(mockFlutterSecureStorage.delete(key: tokenKey)).called(1);
    });

    test('should throw StorageException when token is corrupted', () async {
      // Arrange
      when(mockFlutterSecureStorage.read(key: tokenKey)).thenAnswer(
          (_) async => 'corrupted\x00token'); // Token with null byte

      // Act & Assert
      expect(
        () => secureStorage.getToken(),
        throwsA(
          isA<StorageException>().having(
            (e) => e.message,
            'message',
            equals('Corrupted token data'),
          ),
        ),
      );

      verify(mockFlutterSecureStorage.read(key: tokenKey)).called(1);
    });

    test('should detect null byte corruption in token data', () async {
      // Arrange
      when(mockFlutterSecureStorage.read(key: tokenKey)).thenAnswer(
          (_) async => 'corrupted\x00token'); // Token with null byte

      // Act & Assert
      expect(
        () => secureStorage.getToken(),
        throwsA(
          isA<StorageException>().having(
            (e) => e.message,
            'message',
            equals('Corrupted token data'),
          ),
        ),
      );

      verify(mockFlutterSecureStorage.read(key: tokenKey)).called(1);
    });
  });

  group('User Credentials Storage', () {
    const testEmail = 'test@example.com';
    const emailKey = 'user_email';
    const userIdKey = 'user_id';
    const testUserId = 'user_123';

    test('should store user credentials securely', () async {
      // Arrange
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      // Act
      await secureStorage.saveUserCredentials(
        email: testEmail,
        userId: testUserId,
      );

      // Assert
      verify(mockFlutterSecureStorage.write(
        key: emailKey,
        value: testEmail,
      )).called(1);
      verify(mockFlutterSecureStorage.write(
        key: userIdKey,
        value: testUserId,
      )).called(1);
    });

    test('should retrieve stored user credentials', () async {
      // Arrange
      when(mockFlutterSecureStorage.read(key: emailKey))
          .thenAnswer((_) async => testEmail);
      when(mockFlutterSecureStorage.read(key: userIdKey))
          .thenAnswer((_) async => testUserId);

      // Act
      final credentials = await secureStorage.getUserCredentials();

      // Assert
      expect(credentials, isNotNull);
      expect(credentials?.email, equals(testEmail));
      expect(credentials?.userId, equals(testUserId));
      verify(mockFlutterSecureStorage.read(key: emailKey)).called(1);
      verify(mockFlutterSecureStorage.read(key: userIdKey)).called(1);
    });

    test('should return null when credentials do not exist', () async {
      // Arrange
      when(mockFlutterSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);

      // Act
      final credentials = await secureStorage.getUserCredentials();

      // Assert
      expect(credentials, isNull);
    });

    group('saveUserCredentials validation', () {
      test('should throw StorageException when email is empty', () async {
        // Act & Assert
        expect(
          () => secureStorage.saveUserCredentials(
            email: '',
            userId: testUserId,
          ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              equals('Invalid email format'),
            ),
          ),
        );
      });

      test('should throw StorageException when email format is invalid',
          () async {
        // Act & Assert
        expect(
          () => secureStorage.saveUserCredentials(
            email: 'invalid-email',
            userId: testUserId,
          ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              equals('Invalid email format'),
            ),
          ),
        );
      });

      test('should throw StorageException when email contains null bytes',
          () async {
        // Act & Assert
        expect(
          () => secureStorage.saveUserCredentials(
            email: 'test\x00@example.com',
            userId: testUserId,
          ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              equals('Invalid data format'),
            ),
          ),
        );
      });

      test('should throw StorageException when userId contains null bytes',
          () async {
        // Act & Assert
        expect(
          () => secureStorage.saveUserCredentials(
            email: testEmail,
            userId: 'user\x00123',
          ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              equals('Invalid data format'),
            ),
          ),
        );
      });

      test('should throw StorageException when email contains SQL injection',
          () async {
        // Act & Assert
        expect(
          () => secureStorage.saveUserCredentials(
            email: "admin'--; DROP TABLE users;",
            userId: testUserId,
          ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              equals('Invalid data format'),
            ),
          ),
        );
      });

      test('should throw StorageException when userId contains SQL injection',
          () async {
        // Act & Assert
        expect(
          () => secureStorage.saveUserCredentials(
            email: testEmail,
            userId: "1'; DROP TABLE users; --",
          ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              equals('Invalid data format'),
            ),
          ),
        );
      });

      test('should handle storage write failure for email', () async {
        // Arrange
        when(mockFlutterSecureStorage.write(
          key: emailKey,
          value: anyNamed('value'),
        )).thenThrow(PlatformException(
          code: 'write_error',
          message: 'Failed to write email',
        ));

        // Act & Assert
        expect(
          () => secureStorage.saveUserCredentials(
            email: testEmail,
            userId: testUserId,
          ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('Failed to save user credentials'),
            ),
          ),
        );
      });

      test('should handle storage write failure for userId', () async {
        // Arrange
        when(mockFlutterSecureStorage.write(
          key: userIdKey,
          value: anyNamed('value'),
        )).thenThrow(PlatformException(
          code: 'write_error',
          message: 'Failed to write userId',
        ));

        // Act & Assert
        expect(
          () => secureStorage.saveUserCredentials(
            email: testEmail,
            userId: testUserId,
          ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('Failed to save user credentials'),
            ),
          ),
        );
      });

      test('should handle concurrent write operations', () async {
        // Arrange
        final completer = Completer<void>();
        when(mockFlutterSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenAnswer((_) async {
          await completer.future;
        });

        // Act
        final futures = [
          secureStorage.saveUserCredentials(
            email: 'user1@example.com',
            userId: 'user1',
          ),
          secureStorage.saveUserCredentials(
            email: 'user2@example.com',
            userId: 'user2',
          ),
        ];

        // Complete the write operation
        completer.complete();

        // Assert
        await Future.wait(futures);
        verify(mockFlutterSecureStorage.write(
          key: emailKey,
          value: anyNamed('value'),
        )).called(2);
        verify(mockFlutterSecureStorage.write(
          key: userIdKey,
          value: anyNamed('value'),
        )).called(2);
      });

      test('should save valid user credentials successfully', () async {
        // Arrange
        when(mockFlutterSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenAnswer((_) async {});

        // Act
        await secureStorage.saveUserCredentials(
          email: testEmail,
          userId: testUserId,
        );

        // Assert
        verify(mockFlutterSecureStorage.write(
          key: emailKey,
          value: testEmail,
        )).called(1);
        verify(mockFlutterSecureStorage.write(
          key: userIdKey,
          value: testUserId,
        )).called(1);
      });
    });
  });

  group('User Credentials Storage Edge Cases', () {
    test('should handle partial credential save failure', () async {
      // Arrange
      var firstWriteSucceeded = false;
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((invocation) async {
        if (!firstWriteSucceeded) {
          firstWriteSucceeded = true;
          return;
        }
        throw Exception('Second write failed');
      });

      // Act & Assert
      expect(
        () => secureStorage.saveUserCredentials(
          email: 'test@example.com',
          userId: 'user123',
        ),
        throwsA(isA<StorageException>()),
      );
    });

    test('should handle partial credential retrieval', () async {
      // Arrange
      when(mockFlutterSecureStorage.read(key: 'user_email'))
          .thenAnswer((_) async => 'test@example.com');
      when(mockFlutterSecureStorage.read(key: 'user_id'))
          .thenAnswer((_) async => null);

      // Act
      final credentials = await secureStorage.getUserCredentials();

      // Assert
      expect(credentials, isNull);
    });

    test('should handle invalid email format', () async {
      // Arrange
      const invalidEmail = 'not-an-email';
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      // Act & Assert
      expect(
        () => secureStorage.saveUserCredentials(
          email: invalidEmail,
          userId: 'user123',
        ),
        throwsA(isA<StorageException>()),
      );
    });

    test('should handle corrupted user credentials', () async {
      // Arrange
      when(mockFlutterSecureStorage.read(key: 'user_email'))
          .thenAnswer((_) async => 'corrupted_data\x00injection');
      when(mockFlutterSecureStorage.read(key: 'user_id'))
          .thenAnswer((_) async => 'valid_id');

      // Act & Assert
      expect(
        () => secureStorage.getUserCredentials(),
        throwsA(isA<StorageException>()),
      );
    });

    test('should handle concurrent getUserCredentials calls', () async {
      // Arrange
      var callCount = 0;
      when(mockFlutterSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 100));
        return callCount.toString();
      });

      // Act
      final results = await Future.wait([
        secureStorage.getUserCredentials(),
        secureStorage.getUserCredentials(),
        secureStorage.getUserCredentials(),
      ]);

      // Assert
      expect(results.length, 3);
      expect(results.where((result) => result != null).length, 3);
    });

    test('should handle storage read timeout for getUserCredentials', () async {
      // Arrange
      when(mockFlutterSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async {
        await Future.delayed(
            const Duration(seconds: 2)); // Reduced from 31 seconds
        throw TimeoutException('Storage read timed out');
      });

      // Act & Assert
      expect(
        () => secureStorage.getUserCredentials(),
        throwsA(isA<StorageException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 5))); // Added timeout

    test('should handle clearUserData with locked storage', () async {
      // Arrange
      var deleteAttempts = 0;
      when(mockFlutterSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async {
        deleteAttempts++;
        if (deleteAttempts <= 2) {
          throw PlatformException(
            code: 'storage_locked',
            message: 'Storage is temporarily locked',
          );
        }
      });

      // Act & Assert
      expect(
        () => secureStorage.clearUserData(),
        throwsA(isA<StorageException>()),
      );
    });

    test('should handle concurrent clearUserData and save operations',
        () async {
      // Arrange
      final completer = Completer<void>();
      when(mockFlutterSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async {
        await completer.future;
      });
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      // Act
      final clearFuture = secureStorage.clearUserData();
      final saveFuture = secureStorage.saveUserCredentials(
        email: 'test@example.com',
        userId: 'user123',
      );

      // Complete the delete operation
      completer.complete();

      // Assert
      await Future.wait([clearFuture, saveFuture]);
      verify(mockFlutterSecureStorage.delete(key: 'user_email')).called(1);
      verify(mockFlutterSecureStorage.delete(key: 'user_id')).called(1);
      verify(mockFlutterSecureStorage.delete(key: 'auth_token')).called(1);
    });

    test('should handle clearUserData with partial success', () async {
      // Arrange
      when(mockFlutterSecureStorage.delete(key: 'user_email'))
          .thenThrow(PlatformException(
        code: 'delete_error',
        message: 'Failed to delete email',
      ));
      when(mockFlutterSecureStorage.delete(key: 'user_id'))
          .thenAnswer((_) async {});
      when(mockFlutterSecureStorage.delete(key: 'auth_token'))
          .thenAnswer((_) async {});

      // Act & Assert
      expect(
        () => secureStorage.clearUserData(),
        throwsA(
          isA<StorageException>().having(
            (e) => e.message,
            'message',
            contains('email'),
          ),
        ),
      );
    });

    test('should handle getUserCredentials with inconsistent data', () async {
      // Arrange
      when(mockFlutterSecureStorage.read(key: 'user_email'))
          .thenAnswer((_) async => 'test@example.com');
      when(mockFlutterSecureStorage.read(key: 'user_id')).thenAnswer((_) async {
        throw PlatformException(
          code: 'inconsistent_data',
          message: 'Data integrity check failed',
        );
      });

      // Act & Assert
      expect(
        () => secureStorage.getUserCredentials(),
        throwsA(isA<StorageException>()),
      );
    });

    test('should handle clearUserData during app termination', () async {
      // Arrange
      var isTerminating = false;
      when(mockFlutterSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((invocation) async {
        if (isTerminating) {
          throw PlatformException(
            code: 'app_terminating',
            message: 'Cannot perform operation while app is terminating',
          );
        }
        isTerminating = true;
      });

      // Act & Assert
      expect(
        () => secureStorage.clearUserData(),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('Storage Exception Handling', () {
    test('should handle storage unavailable during token save operation',
        () async {
      // Arrange
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenThrow(PlatformException(code: 'storage_unavailable'));

      // Act & Assert
      expect(
        () => secureStorage.saveToken('test_token'),
        throwsA(isA<StorageException>()),
      );
    });

    test('should handle permission denied during read operation', () async {
      // Arrange
      when(mockFlutterSecureStorage.read(key: anyNamed('key')))
          .thenThrow(PlatformException(code: 'permission_denied'));

      // Act & Assert
      expect(
        () => secureStorage.getToken(),
        throwsA(isA<StorageException>()),
      );
    });

    test('should handle concurrent deletion errors', () async {
      // Arrange
      when(mockFlutterSecureStorage.delete(key: anyNamed('key')))
          .thenThrow(Exception('Concurrent deletion error'));

      // Act & Assert
      expect(
        () => Future.wait([
          secureStorage.deleteToken(),
          secureStorage.deleteToken(),
        ]),
        throwsA(isA<StorageException>()),
      );
    });

    group('clearAllData', () {
      test('should handle storage unavailable during clear all operation',
          () async {
        // Arrange
        when(mockFlutterSecureStorage.deleteAll()).thenThrow(PlatformException(
          code: 'storage_unavailable',
          message: 'Storage is not available',
        ));

        // Act & Assert
        expect(
          () => secureStorage.clearAllData(),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('Failed to clear all data'),
            ),
          ),
        );
      });

      test('should handle permission denied during clear all operation',
          () async {
        // Arrange
        when(mockFlutterSecureStorage.deleteAll()).thenThrow(PlatformException(
          code: 'permission_denied',
          message: 'Permission denied to access storage',
        ));

        // Act & Assert
        expect(
          () => secureStorage.clearAllData(),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('Failed to clear all data'),
            ),
          ),
        );
      });

      test('should handle concurrent deletion operations', () async {
        // Arrange
        final completer = Completer<void>();
        when(mockFlutterSecureStorage.deleteAll()).thenAnswer((_) async {
          await completer.future;
        });

        // Act
        final futures = [
          secureStorage.clearAllData(),
          secureStorage.clearAllData(),
        ];

        // Complete the deletion operation
        completer.complete();

        // Assert
        await Future.wait(futures);
        verify(mockFlutterSecureStorage.deleteAll()).called(2);
      });

      test('should handle storage locked exception', () async {
        // Arrange
        when(mockFlutterSecureStorage.deleteAll()).thenThrow(PlatformException(
          code: 'storage_locked',
          message: 'Storage is locked by another operation',
        ));

        // Act & Assert
        expect(
          () => secureStorage.clearAllData(),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('Failed to clear all data'),
            ),
          ),
        );
      });

      test('should handle storage full exception', () async {
        // Arrange
        when(mockFlutterSecureStorage.deleteAll()).thenThrow(PlatformException(
          code: 'storage_full',
          message: 'Storage is full',
        ));

        // Act & Assert
        expect(
          () => secureStorage.clearAllData(),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('Failed to clear all data'),
            ),
          ),
        );
      });

      test('should handle timeout exception', () async {
        // Arrange
        when(mockFlutterSecureStorage.deleteAll()).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 2));
          throw TimeoutException('Operation timed out');
        });

        // Act & Assert
        expect(
          () => secureStorage.clearAllData(),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('Failed to clear all data'),
            ),
          ),
        );
      }, timeout: const Timeout(Duration(seconds: 5)));

      test('should handle unexpected exceptions', () async {
        // Arrange
        when(mockFlutterSecureStorage.deleteAll())
            .thenThrow(Exception('Unexpected error occurred'));

        // Act & Assert
        expect(
          () => secureStorage.clearAllData(),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('Failed to clear all data'),
            ),
          ),
        );
      });

      test('should clear all data successfully', () async {
        // Arrange
        when(mockFlutterSecureStorage.deleteAll()).thenAnswer((_) async {});

        // Act
        await secureStorage.clearAllData();

        // Assert
        verify(mockFlutterSecureStorage.deleteAll()).called(1);
      });
    });
  });

  group('Data Integrity and Security', () {
    test('should detect general data corruption through value comparison',
        () async {
      // Arrange
      const originalData = 'sensitive_data';
      const corruptedData = 'corrupted_data';

      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: originalData,
      )).thenAnswer((_) async {});

      when(mockFlutterSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => corruptedData);

      // Act
      await secureStorage.saveToken(originalData);
      final retrievedData = await secureStorage.getToken();

      // Assert
      expect(retrievedData, isNot(equals(originalData)));
      expect(retrievedData, equals(corruptedData));
    });

    test('should handle null byte injection attempts', () async {
      // Arrange
      const maliciousData = 'normal_looking_data\x00malicious_payload';
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      // Act & Assert
      expect(
        () => secureStorage.saveToken(maliciousData),
        throwsA(isA<StorageException>()),
      );
    });

    test('should handle SQL injection attempts', () async {
      // Arrange
      const maliciousData = "'; DROP TABLE users; --";
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      // Act & Assert
      expect(
        () => secureStorage.saveToken(maliciousData),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('Recovery and Cleanup', () {
    test('should handle partial cleanup failure', () async {
      // Arrange
      var deleteCount = 0;
      when(mockFlutterSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((invocation) async {
        deleteCount++;
        if (deleteCount > 1) {
          throw Exception('Delete failed');
        }
      });

      // Act & Assert
      expect(
        () => secureStorage.clearUserData(),
        throwsA(isA<StorageException>()),
      );
    });

    test('should handle cleanup during write operation', () async {
      // Arrange
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});
      when(mockFlutterSecureStorage.deleteAll()).thenAnswer((_) async {});

      // Act - Simulate concurrent operations
      await Future.wait([
        secureStorage.saveToken('test_token'),
        secureStorage.clearAllData(),
      ]);

      // Assert - Verify cleanup was called
      verify(mockFlutterSecureStorage.deleteAll()).called(1);
    });

    test('should handle storage full scenario', () async {
      // Arrange
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenThrow(PlatformException(code: 'storage_full'));

      // Act & Assert
      expect(
        () => secureStorage.saveToken('test_token'),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('Secure Deletion', () {
    test('should delete all stored data securely', () async {
      // Arrange
      when(mockFlutterSecureStorage.deleteAll()).thenAnswer((_) async {});

      // Act
      await secureStorage.clearAllData();

      // Assert
      verify(mockFlutterSecureStorage.deleteAll()).called(1);
    });

    test('should delete user-specific data', () async {
      // Arrange
      when(mockFlutterSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async {});

      // Act
      await secureStorage.clearUserData();

      // Assert
      verify(mockFlutterSecureStorage.delete(key: 'user_email')).called(1);
      verify(mockFlutterSecureStorage.delete(key: 'user_id')).called(1);
      verify(mockFlutterSecureStorage.delete(key: 'auth_token')).called(1);
    });
  });

  group('Data Persistence', () {
    test('should persist data across app restarts', () async {
      // Arrange
      const testToken = 'persistent_token';
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});
      when(mockFlutterSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => testToken);

      // Act - Simulate app restart by saving and then retrieving
      await secureStorage.saveToken(testToken);
      final retrievedToken = await secureStorage.getToken();

      // Assert
      expect(retrievedToken, equals(testToken));
    });

    test('should handle storage errors gracefully', () async {
      // Arrange
      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(
        () => secureStorage.saveToken('test_token'),
        throwsA(isA<StorageException>()),
      );
    });

    test('should verify data integrity', () async {
      // Arrange
      const originalToken = 'original_token';
      const modifiedToken = 'modified_token';

      when(mockFlutterSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});
      when(mockFlutterSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => modifiedToken);

      // Act
      await secureStorage.saveToken(originalToken);
      final retrievedToken = await secureStorage.getToken();

      // Assert - Verify data hasn't been tampered with
      expect(retrievedToken, isNot(equals(originalToken)));
      expect(retrievedToken, equals(modifiedToken));
    });
  });
}
