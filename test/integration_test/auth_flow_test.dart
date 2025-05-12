import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:get/get.dart';
import 'package:authentication/auth/presentation/widgets/login_form.dart';
import 'package:authentication/auth/presentation/widgets/register_form.dart';
import 'package:authentication/app/di/dependencies.dart';
import 'package:authentication/auth/presentation/cubit/auth_cubit.dart';
import 'package:authentication/auth/presentation/cubit/auth_state.dart';
import 'package:authentication/app/navigator/app_navigator.dart';
import 'package:authentication/auth/presentation/screens/home_screen.dart';
import 'package:authentication/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Authentication Flow Tests', () {
    late AuthCubit authCubit;

    setUp(() async {
      Get.reset();
      Dependencies.reset();
      await Dependencies.init();

      authCubit = Get.find<AuthCubit>();
    });

    tearDown(() {
      Get.reset();
      Dependencies.reset();
    });

    Future<void> pumpAndWaitForAnimation(WidgetTester tester) async {
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    Future<void> waitForNavigation(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    Future<void> enterTextInField(
      WidgetTester tester,
      Key fieldKey,
      String text, {
      bool needsScroll = true,
    }) async {
      final finder = find.byKey(fieldKey);
      expect(finder, findsOneWidget,
          reason: 'Field with key: $fieldKey not found');

      if (needsScroll) {
        await tester.ensureVisible(finder);
        await pumpAndWaitForAnimation(tester);
      }

      await tester.tap(finder);
      await tester.pump();
      await tester.enterText(finder, text);
      await pumpAndWaitForAnimation(tester);
    }

    Future<void> tapButton(
      WidgetTester tester,
      Finder buttonFinder, {
      bool needsScroll = true,
    }) async {
      expect(buttonFinder, findsOneWidget, reason: 'Button not found');

      if (needsScroll) {
        await tester.ensureVisible(buttonFinder);
        await pumpAndWaitForAnimation(tester);
      }

      await tester.tap(buttonFinder);
      await pumpAndWaitForAnimation(tester);
    }

    Future<void> pumpTestApp(WidgetTester tester) async {
      // Initialize the app
      app.main();
      await tester.pumpAndSettle();

      // Verify critical dependencies
      expect(Get.find<AuthCubit>(), isNotNull,
          reason: 'AuthCubit not initialized');
      expect(Get.find<AppNavigator>(), isNotNull,
          reason: 'AppNavigator not initialized');
      expect(Dependencies.navigatorKey.currentState, isNotNull,
          reason: 'Navigator state is null');
    }

    testWidgets('Complete Registration to Login Flow', (tester) async {
      await pumpTestApp(tester);
      await waitForNavigation(tester);

      // Verify initial screen
      expect(find.byType(LoginForm), findsOneWidget);

      // Navigate to registration
      await tapButton(tester, find.text('Create an account'));
      await waitForNavigation(tester);
      expect(find.byType(RegisterForm), findsOneWidget);

      // Fill registration form
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await enterTextInField(tester, RegisterForm.nameInputKey, 'Test User');
      await enterTextInField(
          tester, RegisterForm.emailInputKey, 'test$timestamp@example.com');
      await enterTextInField(
          tester, RegisterForm.passwordInputKey, 'Password123!');
      await enterTextInField(
          tester, RegisterForm.confirmPasswordInputKey, 'Password123!');

      // Submit registration
      await tapButton(tester, find.widgetWithText(ElevatedButton, 'Register'));
      await pumpAndWaitForAnimation(tester);
      await waitForNavigation(tester);

      // Verify navigation to home screen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Welcome!'), findsOneWidget);

      // Verify user is authenticated
      expect(authCubit.state, isA<Authenticated>());
      final authState = authCubit.state as Authenticated;
      expect(authState.user.name, equals('Test User'));
      expect(authState.user.email, equals('test$timestamp@example.com'));

      // Logout and navigate to login screen
      await tapButton(tester, find.widgetWithText(ElevatedButton, 'Logout'));
      await pumpAndWaitForAnimation(tester);
      await waitForNavigation(tester);

      // Verify back on login screen and logged out
      expect(authCubit.state, isA<Unauthenticated>());
      expect(find.byType(LoginForm), findsOneWidget);
    });

    testWidgets('Login to Protected Area Flow', (tester) async {
      await pumpTestApp(tester);
      await waitForNavigation(tester);

      // Fill login form
      await enterTextInField(
          tester, LoginForm.emailInputKey, 'test@example.com');
      await enterTextInField(
          tester, LoginForm.passwordInputKey, 'Password123!');

      // Submit login
      await tapButton(tester, find.widgetWithText(ElevatedButton, 'Login'));
      await waitForNavigation(tester);

      // Verify navigation to home screen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Welcome!'), findsOneWidget);

      // Verify user is authenticated
      expect(authCubit.state, isA<Authenticated>());
      final authState = authCubit.state as Authenticated;
      expect(authState.user.email, equals('test@example.com'));
    });

    testWidgets('Invalid Login Attempts', (tester) async {
      await pumpTestApp(tester);
      await waitForNavigation(tester);

      // Try login with empty password
      await enterTextInField(
          tester, LoginForm.emailInputKey, 'test@example.com');
      await enterTextInField(tester, LoginForm.passwordInputKey, '');

      // Submit login and verify validation error
      await tapButton(tester, find.widgetWithText(ElevatedButton, 'Login'));
      await waitForNavigation(tester);

      expect(find.text('Password is required'), findsOneWidget);

      // Try login with invalid email format
      await enterTextInField(tester, LoginForm.emailInputKey, 'invalid-email');
      await enterTextInField(
          tester, LoginForm.passwordInputKey, 'Password123!');

      // Submit login and verify validation error
      await tapButton(tester, find.widgetWithText(ElevatedButton, 'Login'));
      await waitForNavigation(tester);

      expect(find.text('Invalid email format'), findsOneWidget);

      // Try login with non-existent email
      await enterTextInField(
          tester, LoginForm.emailInputKey, 'nonexistent@example.com');
      await enterTextInField(
          tester, LoginForm.passwordInputKey, 'Password123!');

      // Submit login and verify error message
      await tapButton(tester, find.widgetWithText(ElevatedButton, 'Login'));
      await waitForNavigation(tester);

      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(authCubit.state, isA<AuthError>());
    });

    testWidgets('Registration Validation', (tester) async {
      await pumpTestApp(tester);
      await waitForNavigation(tester);

      // Navigate to registration
      await tapButton(tester, find.text('Create an account'));
      await waitForNavigation(tester);

      // Try to register with empty fields
      await tapButton(tester, find.widgetWithText(ElevatedButton, 'Register'));
      await waitForNavigation(tester);

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // Try to register with existing email
      await enterTextInField(tester, RegisterForm.nameInputKey, 'Test User');
      await enterTextInField(
          tester, RegisterForm.emailInputKey, 'existing@example.com');
      await enterTextInField(
          tester, RegisterForm.passwordInputKey, 'Password123!');
      await enterTextInField(
          tester, RegisterForm.confirmPasswordInputKey, 'Password123!');

      // Submit registration and verify error
      await tapButton(tester, find.widgetWithText(ElevatedButton, 'Register'));
      await waitForNavigation(tester);

      expect(find.text('Email already exists'), findsOneWidget);
      expect(authCubit.state, isA<AuthError>());

      // Try to register with mismatched passwords
      await enterTextInField(tester, RegisterForm.nameInputKey, 'Test User');
      await enterTextInField(
          tester, RegisterForm.emailInputKey, 'test@example.com');
      await enterTextInField(
          tester, RegisterForm.passwordInputKey, 'Password123!');
      await enterTextInField(tester, RegisterForm.confirmPasswordInputKey,
          'DifferentPassword123!');

      // Submit registration and verify validation error
      await tapButton(tester, find.widgetWithText(ElevatedButton, 'Register'));
      await waitForNavigation(tester);

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Navigation Between Login and Register', (tester) async {
      await pumpTestApp(tester);
      await waitForNavigation(tester);

      // Ensure we start with a clean state
      await authCubit.logout();
      await waitForNavigation(tester);

      // Verify starting at login screen
      expect(find.byType(LoginForm), findsOneWidget);

      // Navigate to registration
      await tapButton(tester, find.text('Create an account'));
      await waitForNavigation(tester);
      expect(find.byType(RegisterForm), findsOneWidget);

      // Navigate back to login
      await tapButton(tester, find.text('Already have an account?'));
      await waitForNavigation(tester);
      expect(find.byType(LoginForm), findsOneWidget);

      // Verify state is maintained
      expect(authCubit.state, isA<Unauthenticated>());
    });
  });
}
