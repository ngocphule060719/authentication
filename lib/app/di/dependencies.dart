import 'package:authentication/app/navigator/app_navigator.dart';
import 'package:authentication/app/navigator/app_navigator_impl.dart';
import 'package:authentication/auth/data/datasources/auth_local_data_source.dart';
import 'package:authentication/auth/data/datasources/auth_remote_data_source.dart';
import 'package:authentication/auth/data/datasources/implementations/auth_local_data_source_impl.dart';
import 'package:authentication/auth/data/datasources/implementations/auth_remote_data_source_impl.dart';
import 'package:authentication/auth/data/repositories/auth_repository_impl.dart';
import 'package:authentication/auth/domain/repositories/auth_repository.dart';
import 'package:authentication/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class Dependencies {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) {
      return;
    }

    // Core dependencies
    Get.put<GlobalKey<NavigatorState>>(navigatorKey, permanent: true);
    Get.put(const FlutterSecureStorage(), permanent: true);

    // Navigator - must be initialized early
    Get.put<AppNavigator>(
      AppNavigatorImpl(navigatorKey: navigatorKey),
      permanent: true,
    );

    // Data sources - using put instead of lazyPut for test stability
    Get.put<AuthLocalDataSource>(
      AuthLocalDataSourceImpl(
        secureStorage: Get.find<FlutterSecureStorage>(),
      ),
      permanent: true,
    );

    Get.put<AuthRemoteDataSource>(
      AuthRemoteDataSourceImpl(),
      permanent: true,
    );

    // Repository
    Get.put<AuthRepository>(
      AuthRepositoryImpl(
        localDataSource: Get.find<AuthLocalDataSource>(),
        remoteDataSource: Get.find<AuthRemoteDataSource>(),
      ),
      permanent: true,
    );

    // Cubit
    Get.put<AuthCubit>(
      AuthCubit(
        authRepository: Get.find<AuthRepository>(),
      ),
      permanent: true,
    );

    _initialized = true;

    // Allow time for all dependencies to initialize
    await Future.delayed(const Duration(milliseconds: 100));
  }

  static void reset() {
    _initialized = false;
    Get.reset();
  }
}
