import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:authentication/auth/domain/repositories/auth_repository.dart';
import 'package:authentication/auth/domain/models/auth_result.dart';
import 'package:authentication/auth/domain/models/user.dart';
import 'package:authentication/auth/domain/exceptions/auth_exceptions.dart';
import 'package:authentication/auth/presentation/cubit/auth_cubit.dart';
import 'package:authentication/auth/presentation/cubit/auth_state.dart';
import 'auth_cubit_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late AuthCubit authCubit;
  late MockAuthRepository mockAuthRepository;

  const testUser = User(
    id: '1',
    email: 'test@example.com',
    name: 'Test User',
  );

  const testAuthResult = AuthResult(
    user: testUser,
    token: 'test_token',
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    // Set up default mock responses
    when(mockAuthRepository.isAuthenticated()).thenAnswer((_) async => false);
    when(mockAuthRepository.getToken()).thenAnswer((_) async => null);
    when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => testUser);
  });

  tearDown(() {
    authCubit.close();
  });

  Future<void> setupAuthCubit() async {
    authCubit = AuthCubit(
      authRepository: mockAuthRepository,
    );
    await Future.delayed(const Duration(milliseconds: 50));
  }

  group('AuthCubit States', () {
    test('should emit Unauthenticated after initialization', () async {
      await setupAuthCubit();
      expect(authCubit.state, isA<Unauthenticated>());
      verify(mockAuthRepository.isAuthenticated()).called(1);
    });

    test('should emit Unauthenticated when not authenticated', () async {
      await setupAuthCubit();

      expect(authCubit.state, isA<Unauthenticated>());
      verify(mockAuthRepository.isAuthenticated()).called(1);
    });

    test('should emit Authenticated when authenticated', () async {
      when(mockAuthRepository.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthRepository.getToken()).thenAnswer((_) async => 'test_token');

      await setupAuthCubit();

      expect(authCubit.state, isA<Authenticated>());
      verify(mockAuthRepository.isAuthenticated()).called(1);
      verify(mockAuthRepository.getToken()).called(1);
      verify(mockAuthRepository.getCurrentUser()).called(1);
    });
  });

  group('Login Flow', () {
    test('should emit [AuthLoading, Authenticated] when login is successful',
        () async {
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => testAuthResult);

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>(),
        ]),
      );

      await authCubit.login(
        email: 'test@example.com',
        password: 'password123',
      );

      verify(mockAuthRepository.login(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test(
        'should emit [AuthLoading, AuthError] when login fails with invalid credentials',
        () async {
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(const AuthException('Invalid credentials'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'Invalid credentials'),
        ]),
      );

      await authCubit.login(
        email: 'test@example.com',
        password: 'wrong_password',
      );
    });

    test(
        'should emit [AuthLoading, AuthError] when login fails with network error',
        () async {
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(const AuthException('Network connection failed'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'Network connection failed'),
        ]),
      );

      await authCubit.login(
        email: 'test@example.com',
        password: 'password123',
      );
    });

    test('should emit [AuthLoading, AuthError] when login times out', () async {
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        throw TimeoutException('Login request timed out');
      });

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'An unexpected error occurred'),
        ]),
      );

      await authCubit.login(
        email: 'test@example.com',
        password: 'password123',
      );
    });

    test('should handle concurrent login attempts gracefully', () async {
      final completer = Completer<void>();
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async {
        await completer.future;
        throw const AuthException('Concurrent login not allowed');
      });

      await setupAuthCubit();

      // Start first login attempt
      final firstLogin = authCubit.login(
        email: 'test@example.com',
        password: 'password123',
      );

      // Wait for the loading state
      await Future.delayed(const Duration(milliseconds: 10));

      // Start second login attempt
      final secondLogin = authCubit.login(
        email: 'test@example.com',
        password: 'password123',
      );

      // Verify states
      expect(authCubit.state, isA<AuthLoading>());

      // Complete the future to trigger error
      completer.complete();

      // Wait for both operations to complete
      await Future.wait([firstLogin, secondLogin]);

      // Verify final error state
      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message,
          'Concurrent login not allowed');
    });
  });

  group('Register Flow', () {
    test(
        'should emit [AuthLoading, Authenticated] when registration is successful',
        () async {
      when(mockAuthRepository.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      )).thenAnswer((_) async => testAuthResult);

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>(),
        ]),
      );

      await authCubit.register(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      );

      verify(mockAuthRepository.register(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      )).called(1);
    });

    test('should emit [AuthLoading, AuthError] when registration fails',
        () async {
      when(mockAuthRepository.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      )).thenThrow(const AuthException('Email already exists'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'Email already exists'),
        ]),
      );

      await authCubit.register(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      );
    });

    test(
        'should emit [AuthLoading, AuthError] when registration fails with email already exists',
        () async {
      when(mockAuthRepository.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      )).thenThrow(const AuthException('Email already exists'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'Email already exists'),
        ]),
      );

      await authCubit.register(
        email: 'existing@example.com',
        password: 'password123',
        name: 'Test User',
      );
    });

    test(
        'should emit [AuthLoading, AuthError] when registration fails with invalid email format',
        () async {
      when(mockAuthRepository.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      )).thenThrow(const AuthException('Invalid email format'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'Invalid email format'),
        ]),
      );

      await authCubit.register(
        email: 'invalid-email',
        password: 'password123',
        name: 'Test User',
      );
    });

    test(
        'should emit [AuthLoading, AuthError] when registration fails with weak password',
        () async {
      when(mockAuthRepository.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      )).thenThrow(const AuthException('Password is too weak'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'Password is too weak'),
        ]),
      );

      await authCubit.register(
        email: 'test@example.com',
        password: 'weak',
        name: 'Test User',
      );
    });

    test(
        'should emit [AuthLoading, AuthError] when registration fails with network error',
        () async {
      when(mockAuthRepository.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      )).thenThrow(const AuthException('Network connection failed'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'Network connection failed'),
        ]),
      );

      await authCubit.register(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      );
    });

    test('should emit [AuthLoading, AuthError] when registration times out',
        () async {
      when(mockAuthRepository.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        throw TimeoutException('Registration request timed out');
      });

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'An unexpected error occurred'),
        ]),
      );

      await authCubit.register(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      );
    });

    test('should handle concurrent registration attempts gracefully', () async {
      final completer = Completer<void>();
      when(mockAuthRepository.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      )).thenAnswer((_) async {
        await completer.future;
        throw const AuthException('Concurrent registration not allowed');
      });

      await setupAuthCubit();

      // Start first registration attempt
      final firstRegister = authCubit.register(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      );

      // Wait for the loading state
      await Future.delayed(const Duration(milliseconds: 10));

      // Start second registration attempt
      final secondRegister = authCubit.register(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      );

      // Verify states
      expect(authCubit.state, isA<AuthLoading>());

      // Complete the future to trigger error
      completer.complete();

      // Wait for both operations to complete
      await Future.wait([firstRegister, secondRegister]);

      // Verify final error state
      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message,
          'Concurrent registration not allowed');
    });
  });

  group('Logout Flow', () {
    test('should emit Unauthenticated when logout is successful', () async {
      when(mockAuthRepository.logout()).thenAnswer((_) async {});

      await setupAuthCubit();

      // Start listening to the stream before calling logout
      final streamSubscription = authCubit.stream.listen(null);
      addTearDown(streamSubscription.cancel);

      await authCubit.logout();

      verify(mockAuthRepository.logout()).called(1);
      expect(authCubit.state, isA<Unauthenticated>());
    });

    test('should emit AuthError when logout fails with network error',
        () async {
      when(mockAuthRepository.logout())
          .thenThrow(const AuthException('Network connection failed'));

      await setupAuthCubit();

      // Start listening to the stream before calling logout
      final streamSubscription = authCubit.stream.listen(null);
      addTearDown(streamSubscription.cancel);

      await authCubit.logout();

      expect(authCubit.state, isA<AuthError>());
      expect(
          (authCubit.state as AuthError).message, 'Network connection failed');
    });
  });

  group('Password Reset Flow', () {
    test(
        'should emit [AuthLoading, Unauthenticated] when password reset request is successful',
        () async {
      when(mockAuthRepository.requestPasswordReset(
        email: anyNamed('email'),
      )).thenAnswer((_) async {});

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ]),
      );

      await authCubit.requestPasswordReset(email: 'test@example.com');
      verify(mockAuthRepository.requestPasswordReset(
        email: 'test@example.com',
      )).called(1);
    });

    test('should emit [AuthLoading, AuthError] when email is not registered',
        () async {
      when(mockAuthRepository.requestPasswordReset(
        email: anyNamed('email'),
      )).thenThrow(const AuthException('Email not found'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>((state) => state.message == 'Email not found'),
        ]),
      );

      await authCubit.requestPasswordReset(email: 'nonexistent@example.com');
    });

    test('should emit [AuthLoading, AuthError] when email format is invalid',
        () async {
      when(mockAuthRepository.requestPasswordReset(
        email: anyNamed('email'),
      )).thenThrow(const AuthException('Invalid email format'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'Invalid email format'),
        ]),
      );

      await authCubit.requestPasswordReset(email: 'invalid_email');
    });

    test(
        'should emit [AuthLoading, AuthError] when reset request is rate limited',
        () async {
      when(mockAuthRepository.requestPasswordReset(
        email: anyNamed('email'),
      )).thenThrow(const AuthException('Too many requests'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>((state) => state.message == 'Too many requests'),
        ]),
      );

      await authCubit.requestPasswordReset(email: 'test@example.com');
    });

    test('should emit [AuthLoading, AuthError] when network error occurs',
        () async {
      when(mockAuthRepository.requestPasswordReset(
        email: anyNamed('email'),
      )).thenThrow(const AuthException('Network connection failed'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'Network connection failed'),
        ]),
      );

      await authCubit.requestPasswordReset(email: 'test@example.com');
    });

    test('should emit [AuthLoading, AuthError] when server error occurs',
        () async {
      when(mockAuthRepository.requestPasswordReset(
        email: anyNamed('email'),
      )).thenThrow(const AuthException('Internal server error'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'Internal server error'),
        ]),
      );

      await authCubit.requestPasswordReset(email: 'test@example.com');
    });

    test('should emit [AuthLoading, AuthError] when request times out',
        () async {
      when(mockAuthRepository.requestPasswordReset(
        email: anyNamed('email'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        throw TimeoutException('Password reset request timed out');
      });

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'An unexpected error occurred'),
        ]),
      );

      await authCubit.requestPasswordReset(email: 'test@example.com');
    });

    test('should handle concurrent password reset requests gracefully',
        () async {
      final completer = Completer<void>();
      when(mockAuthRepository.requestPasswordReset(
        email: anyNamed('email'),
      )).thenAnswer((_) async {
        await completer.future;
        throw const AuthException('Concurrent password reset not allowed');
      });

      await setupAuthCubit();

      // Start first password reset request
      final firstRequest =
          authCubit.requestPasswordReset(email: 'test@example.com');

      // Wait for the loading state
      await Future.delayed(const Duration(milliseconds: 10));

      // Start second password reset request
      final secondRequest =
          authCubit.requestPasswordReset(email: 'test@example.com');

      // Verify states
      expect(authCubit.state, isA<AuthLoading>());

      // Complete the future to trigger error
      completer.complete();

      // Wait for both operations to complete
      await Future.wait([firstRequest, secondRequest]);

      // Verify final error state
      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message,
          'Concurrent password reset not allowed');
    });

    test('should emit [AuthLoading, AuthError] when unexpected error occurs',
        () async {
      when(mockAuthRepository.requestPasswordReset(
        email: anyNamed('email'),
      )).thenThrow(Exception('Unexpected error occurred'));

      await setupAuthCubit();

      expectLater(
        authCubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>(
              (state) => state.message == 'An unexpected error occurred'),
        ]),
      );

      await authCubit.requestPasswordReset(email: 'test@example.com');
    });
  });

  group('checkAuthStatus', () {
    test('should emit AuthError when isAuthenticated throws AuthException',
        () async {
      when(mockAuthRepository.isAuthenticated())
          .thenThrow(const AuthException('Failed to check auth status'));

      await setupAuthCubit();

      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message,
          'Failed to check auth status');
    });

    test('should emit AuthError when getToken throws StorageException',
        () async {
      when(mockAuthRepository.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthRepository.getToken())
          .thenThrow(StorageException('Failed to get token'));

      await setupAuthCubit();

      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message,
          'An unexpected error occurred');
    });

    test('should emit Unauthenticated when getToken returns null', () async {
      when(mockAuthRepository.isAuthenticated()).thenAnswer((_) async => true);
      when(mockAuthRepository.getToken()).thenAnswer((_) async => null);

      await setupAuthCubit();

      expect(authCubit.state, isA<Unauthenticated>());
    });

    test('should emit AuthError when any unexpected exception occurs',
        () async {
      when(mockAuthRepository.isAuthenticated())
          .thenThrow(Exception('Unexpected error'));

      await setupAuthCubit();

      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message,
          'An unexpected error occurred');
    });

    test('should handle concurrent checkAuthStatus calls gracefully', () async {
      final completer = Completer<void>();
      when(mockAuthRepository.isAuthenticated()).thenAnswer((_) async {
        await completer.future;
        throw const AuthException('Failed to check auth status');
      });

      await setupAuthCubit();

      // Trigger concurrent calls
      final futures = Future.wait([
        authCubit.checkAuthStatus(),
        authCubit.checkAuthStatus(),
      ]);

      // Complete the future after a short delay
      await Future.delayed(const Duration(milliseconds: 50));
      completer.complete();

      // Wait for all operations to complete
      await futures;
      await Future.delayed(const Duration(milliseconds: 50));

      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message,
          'Failed to check auth status');
    });

    test('should emit AuthError when network timeout occurs', () async {
      when(mockAuthRepository.isAuthenticated()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        throw TimeoutException('Network timeout');
      });

      await setupAuthCubit();

      expect(authCubit.state, isA<AuthError>());
      expect((authCubit.state as AuthError).message,
          'An unexpected error occurred');
    });
  });

  group('Safe State Emission', () {
    test('should not emit state after cubit is closed', () async {
      await setupAuthCubit();

      // Get initial state
      final initialState = authCubit.state;

      // Setup logout to be delayed
      when(mockAuthRepository.logout()).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 100)),
      );

      // Start logout process
      final future = authCubit.logout();

      // Close cubit before logout completes
      await authCubit.close();

      // Wait for logout to complete
      await future;

      // Verify state hasn't changed after close
      expect(authCubit.state, equals(initialState));
    });

    test('should handle multiple async operations when closing', () async {
      await setupAuthCubit();

      // Get initial state
      final initialState = authCubit.state;

      // Setup multiple delayed operations
      when(mockAuthRepository.logout()).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 100)),
      );

      // Start multiple operations
      final futures = Future.wait([
        authCubit.logout(),
        authCubit.logout(),
        authCubit.logout(),
      ]);

      // Close cubit while operations are in progress
      await authCubit.close();

      // Wait for all operations to complete
      await futures;

      // Verify state hasn't changed after close
      expect(authCubit.state, equals(initialState));
    });
  });
}
