import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:authentication/auth/presentation/cubit/auth_cubit.dart';
import 'package:authentication/auth/presentation/cubit/auth_state.dart';
import 'package:authentication/auth/domain/validators/auth_validator.dart';
import 'package:get/get.dart';
import 'package:authentication/app/navigator/app_navigator.dart';

class LoginForm extends StatefulWidget {
  static const emailInputKey = Key('loginForm_emailInput_textField');
  static const passwordInputKey = Key('loginForm_passwordInput_textField');

  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(AuthState currentState) async {
    if (currentState is AuthLoading) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await Get.find<AuthCubit>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      bloc: Get.find<AuthCubit>(),
      listener: (context, state) {
        if (state is Authenticated) {
          Get.find<AppNavigator>().toHome();
        }
      },
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: LoginForm.emailInputKey,
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: AuthValidator.validateEmail,
                onChanged: (_) {
                  _formKey.currentState?.validate();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: LoginForm.passwordInputKey,
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: AuthValidator.validatePassword,
                onChanged: (_) {
                  _formKey.currentState?.validate();
                },
              ),
              const SizedBox(height: 24),
              if (state is AuthError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (state is AuthLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async => await _login(state),
                  child: const Text('Login'),
                ),
            ],
          ),
        );
      },
    );
  }
}
