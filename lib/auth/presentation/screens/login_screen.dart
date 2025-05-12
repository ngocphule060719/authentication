import 'package:authentication/app/navigator/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:authentication/auth/presentation/widgets/login_form.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LoginForm(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Get.find<AppNavigator>().toRegister();
                  },
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
