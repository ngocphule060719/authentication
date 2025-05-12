import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:authentication/auth/domain/repositories/auth_repository.dart';
import 'package:authentication/auth/domain/exceptions/auth_exceptions.dart';
import 'package:authentication/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(AuthInitial()) {
    checkAuthStatus();
  }

  void _safeEmit(AuthState state) {
    if (isClosed) {
      return;
    }

    emit(state);
  }

  Future<void> checkAuthStatus() async {
    try {
      _safeEmit(AuthLoading());

      final isAuthenticated = await _authRepository.isAuthenticated();

      if (!isAuthenticated) {
        _safeEmit(Unauthenticated());
        return;
      }

      final token = await _authRepository.getToken();
      if (token == null) {
        _safeEmit(Unauthenticated());
        return;
      }

      final user = await _authRepository.getCurrentUser();
      _safeEmit(Authenticated(user: user, token: token));
    } on AuthException catch (e) {
      _safeEmit(AuthError(e.toString()));
    } catch (e) {
      _safeEmit(const AuthError('An unexpected error occurred'));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      _safeEmit(AuthLoading());

      final result = await _authRepository.login(
        email: email,
        password: password,
      );

      _safeEmit(Authenticated(
        user: result.user,
        token: result.token,
      ));
    } on AuthException catch (e) {
      _safeEmit(AuthError(e.toString()));
    } catch (e) {
      _safeEmit(const AuthError('An unexpected error occurred'));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _safeEmit(AuthLoading());

      final result = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );

      _safeEmit(Authenticated(
        user: result.user,
        token: result.token,
      ));
    } on AuthException catch (e) {
      _safeEmit(AuthError(e.toString()));
    } catch (e) {
      _safeEmit(const AuthError('An unexpected error occurred'));
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      _safeEmit(Unauthenticated());
    } on AuthException catch (e) {
      _safeEmit(AuthError(e.toString()));
    } catch (e) {
      _safeEmit(const AuthError('An unexpected error occurred'));
    }
  }

  Future<void> requestPasswordReset({
    required String email,
  }) async {
    try {
      _safeEmit(AuthLoading());

      await _authRepository.requestPasswordReset(
        email: email,
      );

      _safeEmit(Unauthenticated());
    } on AuthException catch (e) {
      _safeEmit(AuthError(e.toString()));
    } catch (e) {
      _safeEmit(const AuthError('An unexpected error occurred'));
    }
  }
}
