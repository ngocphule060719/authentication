import 'package:authentication/app/navigator/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:authentication/auth/presentation/widgets/register_form.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const RegisterForm(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Get.find<AppNavigator>().pop();
                  },
                  child: const Text('Already have an account?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
