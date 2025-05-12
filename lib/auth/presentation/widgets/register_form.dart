import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:authentication/auth/presentation/cubit/auth_cubit.dart';
import 'package:authentication/auth/presentation/cubit/auth_state.dart';
import 'package:authentication/auth/domain/validators/auth_validator.dart';
import 'package:get/get.dart';
import 'package:authentication/app/navigator/app_navigator.dart';

class RegisterForm extends StatefulWidget {
  static const nameInputKey = Key('registerForm_nameInput_textField');
  static const emailInputKey = Key('registerForm_emailInput_textField');
  static const passwordInputKey = Key('registerForm_passwordInput_textField');
  static const confirmPasswordInputKey =
      Key('registerForm_confirmPasswordInput_textField');

  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register(AuthState currentState) async {
    if (currentState is AuthLoading) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await Get.find<AuthCubit>().register(
      name: _nameController.text.trim(),
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
                key: RegisterForm.nameInputKey,
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your full name',
                ),
                textCapitalization: TextCapitalization.words,
                validator: AuthValidator.validateName,
                onChanged: (_) {
                  _formKey.currentState?.validate();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: RegisterForm.emailInputKey,
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
                key: RegisterForm.passwordInputKey,
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
              const SizedBox(height: 16),
              TextFormField(
                key: RegisterForm.confirmPasswordInputKey,
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) => AuthValidator.validateConfirmPassword(
                  value,
                  _passwordController.text,
                ),
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
                  onPressed: () async => await _register(state),
                  child: const Text('Register'),
                ),
            ],
          ),
        );
      },
    );
  }
}
