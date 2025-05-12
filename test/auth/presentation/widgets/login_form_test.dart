import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:authentication/auth/presentation/cubit/auth_cubit.dart';
import 'package:authentication/auth/presentation/widgets/login_form.dart';
import 'package:authentication/auth/domain/models/user.dart';
import 'package:authentication/auth/presentation/cubit/auth_state.dart';
import 'package:authentication/app/navigator/app_navigator.dart';
import 'login_form_test.mocks.dart';

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

    when(mockAuthCubit.stream)
        .thenAnswer((_) => Stream.fromIterable([AuthInitial()]));
  });

  tearDown(() {
    Get.reset(); // Clean up GetX dependencies after each test
  });

  Widget createWidgetUnderTest() {
    return const GetMaterialApp(
      home: Scaffold(
        body: LoginForm(),
      ),
    );
  }

  group('LoginForm Widget Tests', () {
    testWidgets('should show all required fields initially',
        (WidgetTester tester) async {
      // Setup initial state
      when(mockAuthCubit.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields',
        (WidgetTester tester) async {
      // Setup initial state
      when(mockAuthCubit.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Try to submit without entering any data
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('should show error for invalid email format',
        (WidgetTester tester) async {
      // Setup initial state
      when(mockAuthCubit.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter invalid email
      await tester.enterText(
        find.byKey(LoginForm.emailInputKey),
        'invalid-email',
      );
      await tester.pump();

      // Try to submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Invalid email format'), findsOneWidget);
    });

    testWidgets('should validate password length', (WidgetTester tester) async {
      // Setup initial state
      when(mockAuthCubit.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter short password
      await tester.enterText(
        find.byKey(LoginForm.passwordInputKey),
        'short',
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
        find.byKey(LoginForm.emailInputKey),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(LoginForm.passwordInputKey),
        'Password123',
      );
      await tester.pump();

      // Setup login method to emit loading state immediately
      when(mockAuthCubit.login(
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

      verify(mockAuthCubit.login(
        email: 'test@example.com',
        password: 'Password123',
      )).called(1);

      // Clean up
      await streamController.close();
    });

    testWidgets('should show error message when login fails',
        (WidgetTester tester) async {
      // Setup states
      when(mockAuthCubit.state).thenReturn(AuthInitial());
      when(mockAuthCubit.stream).thenAnswer((_) => Stream.fromIterable([
            AuthInitial(),
            const AuthError('Invalid credentials'),
          ]));

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid data
      await tester.enterText(
        find.byKey(LoginForm.emailInputKey),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(LoginForm.passwordInputKey),
        'WrongPassword123',
      );

      // Validate form
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);

      // Change state to error
      when(mockAuthCubit.state)
          .thenReturn(const AuthError('Invalid credentials'));

      // Submit form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('should handle successful login', (WidgetTester tester) async {
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
        find.byKey(LoginForm.emailInputKey),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(LoginForm.passwordInputKey),
        'Password123',
      );

      // Validate form
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);

      // Change state to authenticated
      when(mockAuthCubit.state)
          .thenReturn(const Authenticated(user: testUser, token: 'test_token'));

      // Submit form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      verify(mockAuthCubit.login(
        email: 'test@example.com',
        password: 'Password123',
      )).called(1);

      // Verify navigation was called
      verify(mockNavigator.toHome()).called(1);
    });

    testWidgets('should toggle password visibility',
        (WidgetTester tester) async {
      // Setup initial state
      when(mockAuthCubit.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Find password field
      final passwordField = find.byKey(LoginForm.passwordInputKey);

      // Initially password should be obscured
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

      // Tap the visibility toggle button
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Password should now be visible
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
    });

    testWidgets('should clear error messages when typing',
        (WidgetTester tester) async {
      // Setup initial state
      when(mockAuthCubit.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Submit empty form to trigger errors
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);

      // Start typing in email field
      await tester.enterText(
        find.byKey(LoginForm.emailInputKey),
        't',
      );
      await tester.pump();

      // Error should be cleared
      expect(find.text('Email is required'), findsNothing);
    });

    testWidgets('should handle network errors gracefully',
        (WidgetTester tester) async {
      // Setup states
      when(mockAuthCubit.state).thenReturn(AuthInitial());
      when(mockAuthCubit.stream).thenAnswer((_) => Stream.fromIterable([
            AuthInitial(),
            const AuthError('Network connection failed'),
          ]));

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid data
      await tester.enterText(
        find.byKey(LoginForm.emailInputKey),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(LoginForm.passwordInputKey),
        'Password123',
      );

      // Validate form
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);

      // Change state to network error
      when(mockAuthCubit.state).thenReturn(
        const AuthError('Network connection failed'),
      );

      // Submit form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
