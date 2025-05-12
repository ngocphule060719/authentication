import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:authentication/app/navigator/app_navigator.dart';
import 'package:authentication/auth/presentation/screens/home_screen.dart';
import 'package:authentication/auth/presentation/screens/login_screen.dart';
import 'package:authentication/auth/presentation/screens/register_screen.dart';
import 'package:authentication/auth/presentation/cubit/auth_cubit.dart';

class AppNavigatorImpl implements AppNavigator {
  final GlobalKey<NavigatorState> navigatorKey;

  AppNavigatorImpl({required this.navigatorKey});

  NavigatorState get _navigator => navigatorKey.currentState!;

  Widget _wrapWithBloc(Widget screen) {
    return BlocProvider<AuthCubit>(
      create: (_) => Get.find<AuthCubit>(),
      child: screen,
    );
  }

  @override
  void toHome() {
    _navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => _wrapWithBloc(const HomeScreen()),
      ),
    );
  }

  @override
  void toLogin() {
    _navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => _wrapWithBloc(const LoginScreen()),
      ),
    );
  }

  @override
  void toRegister() {
    _navigator.push(
      MaterialPageRoute(
        builder: (_) => _wrapWithBloc(const RegisterScreen()),
      ),
    );
  }

  @override
  void popWithResult<T>(T result) {
    _navigator.pop(result);
  }

  @override
  void pop() {
    _navigator.pop();
  }
}
