import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';
import 'package:authentication/app/navigator/app_navigator.dart';
import 'package:authentication/auth/presentation/cubit/auth_cubit.dart';
import 'package:authentication/auth/presentation/cubit/auth_state.dart';
import 'package:authentication/auth/presentation/screens/login_screen.dart';
import 'package:authentication/auth/domain/models/user.dart';
import 'package:authentication/auth/domain/repositories/auth_repository.dart';

@GenerateNiceMocks([
  MockSpec<AuthCubit>(),
  MockSpec<AuthRepository>(),
  MockSpec<NavigatorObserver>(),
  MockSpec<AppNavigator>()
])
import 'login_screen_test.mocks.dart';

void main() {
  late MockAuthCubit authCubit;
  late MockNavigatorObserver navigatorObserver;
  late MockAppNavigator appNavigator;
  late StreamController<AuthState> stateController;

  setUp(() {
    authCubit = MockAuthCubit();
    navigatorObserver = MockNavigatorObserver();
    appNavigator = MockAppNavigator();
    stateController = StreamController<AuthState>();

    when(authCubit.stream).thenAnswer((_) => stateController.stream);
    when(authCubit.state).thenReturn(Unauthenticated());

    // Register dependencies with Get
    Get.put<AppNavigator>(appNavigator);
    Get.put<AuthCubit>(authCubit);
  });

  tearDown(() {
    stateController.close();
    Get.reset();
  });

  Widget createLoginScreen() {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp(
        home: const LoginScreen(),
        navigatorObservers: [navigatorObserver],
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('displays loading indicator when state is AuthLoading',
        (tester) async {
      when(authCubit.state).thenReturn(AuthLoading());

      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('displays error message when state is AuthError',
        (tester) async {
      const errorMessage = 'Invalid credentials';
      when(authCubit.state).thenReturn(const AuthError(errorMessage));

      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('navigates to home screen on successful authentication',
        (tester) async {
      const user = User(id: '1', name: 'Test User', email: 'test@example.com');

      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      // Emit authenticated state
      stateController.add(const Authenticated(user: user, token: 'token'));
      await tester.pumpAndSettle();

      // Verify that toHome was called
      verify(appNavigator.toHome()).called(1);
    });

    testWidgets('navigates to register screen when register link is tapped',
        (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();

      verify(appNavigator.toRegister()).called(1);
    });

    testWidgets('login form validates email and password before submission',
        (tester) async {
      when(authCubit.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      // Try to submit with empty fields
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // Fill in valid data
      await tester.enterText(
          find.byKey(const Key('loginForm_emailInput_textField')),
          'test@example.com');
      await tester.enterText(
          find.byKey(const Key('loginForm_passwordInput_textField')),
          'password123');
      await tester.pump();

      // Submit form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(authCubit.login(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    testWidgets('prevents multiple submissions while loading', (tester) async {
      // Setup loading state
      when(authCubit.state).thenReturn(AuthLoading());
      when(authCubit.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(createLoginScreen());

      // Fill in valid data
      await tester.enterText(
          find.byKey(const Key('loginForm_emailInput_textField')),
          'test@example.com');
      await tester.enterText(
          find.byKey(const Key('loginForm_passwordInput_textField')),
          'password123');
      await tester.pump();

      // Verify loading indicator is shown instead of button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);

      // Verify login was not called
      verifyNever(authCubit.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });
  });
}
