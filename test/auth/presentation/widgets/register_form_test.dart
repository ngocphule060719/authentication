import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:authentication/auth/presentation/cubit/auth_cubit.dart';
import 'package:authentication/auth/presentation/widgets/register_form.dart';
import 'package:authentication/auth/domain/models/user.dart';
import 'package:authentication/auth/presentation/cubit/auth_state.dart';
import 'package:authentication/app/navigator/app_navigator.dart';
import 'register_form_test.mocks.dart';

@GenerateMocks([AuthCubit, AppNavigator])
void main() {
  late MockAuthCubit mockAuthCubit;
  late MockAppNavigator mockNavigator;

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    mockNavigator = MockAppNavigator();

    // Initialize GetX dependencies
    Get.put<AuthCubit>(mockAuthCubit);
    Get.put<AppNavigator>(mockNavigator);

    // Mock the stream getter with initial state
    when(mockAuthCubit.stream)
        .thenAnswer((_) => Stream.fromIterable([AuthInitial()]));
    when(mockAuthCubit.state).thenReturn(AuthInitial());
  });

  tearDown(() {
    Get.reset(); // Clean up GetX dependencies after each test
  });

  Widget createWidgetUnderTest() {
    return const GetMaterialApp(
      home: Scaffold(
        body: RegisterForm(),
      ),
    );
  }

  group('RegisterForm Widget Tests', () {
    testWidgets('should show all required fields initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(TextFormField),
          findsNWidgets(4)); // name, email, password, confirm password
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Try to submit without entering any data
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('should show error for invalid email format',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter invalid email
      await tester.enterText(
        find.byKey(RegisterForm.emailInputKey),
        'invalid-email',
      );
      await tester.pump();

      // Try to submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Invalid email format'), findsOneWidget);
    });

    testWidgets('should validate password strength',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Test weak password
      await tester.enterText(
        find.byKey(RegisterForm.passwordInputKey),
        'weak',
      );
      await tester.pump();

      // Try to submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(
        find.text(
            'Password must be at least 8 characters with numbers and letters'),
        findsOneWidget,
      );

      // Test password without numbers
      await tester.enterText(
        find.byKey(RegisterForm.passwordInputKey),
        'onlyletters',
      );
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(
        find.text('Password must contain at least one number'),
        findsOneWidget,
      );
    });

    testWidgets('should validate password confirmation matching',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter non-matching passwords
      await tester.enterText(
        find.byKey(RegisterForm.passwordInputKey),
        'Password123',
      );
      await tester.enterText(
        find.byKey(RegisterForm.confirmPasswordInputKey),
        'DifferentPassword123',
      );
      await tester.pump();

      // Try to submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should show loading indicator when submitting',
        (WidgetTester tester) async {
      // Setup stream to emit loading state
      final streamController = StreamController<AuthState>.broadcast();
      when(mockAuthCubit.stream).thenAnswer((_) => streamController.stream);
      when(mockAuthCubit.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter valid data
      await tester.enterText(
        find.byKey(RegisterForm.nameInputKey),
        'Test User',
      );
      await tester.enterText(
        find.byKey(RegisterForm.emailInputKey),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(RegisterForm.passwordInputKey),
        'Password123',
      );
      await tester.enterText(
        find.byKey(RegisterForm.confirmPasswordInputKey),
        'Password123',
      );
      await tester.pump();

      // Setup register method to emit loading state immediately
      when(mockAuthCubit.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'Password123',
      )).thenAnswer((_) async {
        when(mockAuthCubit.state).thenReturn(AuthLoading());
        streamController.add(AuthLoading());
        // Don't complete the future yet to keep the loading state
        return Completer<void>().future;
      });

      // Submit form
      await tester.tap(find.byType(ElevatedButton));

      // Wait for the loading state to be processed
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);

      verify(mockAuthCubit.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'Password123',
      )).called(1);

      // Clean up
      await streamController.close();
    });

    testWidgets('should show error message when registration fails',
        (WidgetTester tester) async {
      // Setup cubit to emit error state
      final streamController = StreamController<AuthState>.broadcast();
      when(mockAuthCubit.stream).thenAnswer((_) => streamController.stream);
      when(mockAuthCubit.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter valid data
      await tester.enterText(
        find.byKey(RegisterForm.nameInputKey),
        'Test User',
      );
      await tester.enterText(
        find.byKey(RegisterForm.emailInputKey),
        'existing@example.com',
      );
      await tester.enterText(
        find.byKey(RegisterForm.passwordInputKey),
        'Password123',
      );
      await tester.enterText(
        find.byKey(RegisterForm.confirmPasswordInputKey),
        'Password123',
      );

      // Setup register to emit error
      when(mockAuthCubit.register(
        name: 'Test User',
        email: 'existing@example.com',
        password: 'Password123',
      )).thenAnswer((_) async {
        when(mockAuthCubit.state)
            .thenReturn(const AuthError('Email already exists'));
        streamController.add(const AuthError('Email already exists'));
      });

      // Submit form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Email already exists'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      verify(mockAuthCubit.register(
        name: 'Test User',
        email: 'existing@example.com',
        password: 'Password123',
      )).called(1);

      // Clean up
      await streamController.close();
    });

    testWidgets('should handle successful registration',
        (WidgetTester tester) async {
      const testUser = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
      );

      // Setup states
      when(mockAuthCubit.state).thenReturn(AuthInitial());
      when(mockAuthCubit.stream).thenAnswer((_) => Stream.fromIterable([
            AuthInitial(),
            const Authenticated(user: testUser, token: 'test_token'),
          ]));

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid data
      await tester.enterText(
        find.byKey(RegisterForm.nameInputKey),
        'Test User',
      );
      await tester.enterText(
        find.byKey(RegisterForm.emailInputKey),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(RegisterForm.passwordInputKey),
        'Password123',
      );
      await tester.enterText(
        find.byKey(RegisterForm.confirmPasswordInputKey),
        'Password123',
      );

      // Submit form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      verify(mockAuthCubit.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'Password123',
      )).called(1);

      // Verify navigation was called
      verify(mockNavigator.toHome()).called(1);
    });

    testWidgets('should toggle password visibility',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find password fields
      final passwordField = find.byKey(RegisterForm.passwordInputKey);
      final confirmPasswordField =
          find.byKey(RegisterForm.confirmPasswordInputKey);

      // Initially passwords should be obscured
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: passwordField,
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: confirmPasswordField,
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isTrue,
      );

      // Tap visibility toggles
      await tester.tap(find.byType(IconButton).first);
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();

      // Passwords should now be visible
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: passwordField,
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isFalse,
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: confirmPasswordField,
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isFalse,
      );
    });

    testWidgets('should clear error messages when typing',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Submit empty form to trigger errors
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);

      // Start typing in name field
      await tester.enterText(
        find.byKey(RegisterForm.nameInputKey),
        't',
      );
      await tester.pump();

      // Error should be cleared
      expect(find.text('Name is required'), findsNothing);
    });

    testWidgets('should validate name format', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter invalid name (too short)
      await tester.enterText(
        find.byKey(RegisterForm.nameInputKey),
        'a',
      );
      await tester.pump();

      // Try to submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(
        find.text('Name must be at least 2 characters'),
        findsOneWidget,
      );

      // Enter invalid name (with special characters)
      await tester.enterText(
        find.byKey(RegisterForm.nameInputKey),
        'Test@User#123',
      );
      await tester.pump();

      // Try to submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(
        find.text('Name can only contain letters and spaces'),
        findsOneWidget,
      );
    });

    testWidgets('should handle network errors gracefully',
        (WidgetTester tester) async {
      // Setup cubit to emit network error
      final streamController = StreamController<AuthState>.broadcast();
      when(mockAuthCubit.stream).thenAnswer((_) => streamController.stream);
      when(mockAuthCubit.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter valid data
      await tester.enterText(
        find.byKey(RegisterForm.nameInputKey),
        'Test User',
      );
      await tester.enterText(
        find.byKey(RegisterForm.emailInputKey),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(RegisterForm.passwordInputKey),
        'Password123',
      );
      await tester.enterText(
        find.byKey(RegisterForm.confirmPasswordInputKey),
        'Password123',
      );

      // Setup register to emit network error
      when(mockAuthCubit.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'Password123',
      )).thenAnswer((_) async {
        when(mockAuthCubit.state)
            .thenReturn(const AuthError('Network connection failed'));
        streamController.add(const AuthError('Network connection failed'));
      });

      // Submit form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      verify(mockAuthCubit.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'Password123',
      )).called(1);

      // Clean up
      await streamController.close();
    });
  });
}
