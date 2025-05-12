import 'package:authentication/app/navigator/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:authentication/auth/presentation/cubit/auth_cubit.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async => await _handleLogout(context),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await Get.find<AuthCubit>().logout();
    Get.find<AppNavigator>().toLogin();
  }
}
