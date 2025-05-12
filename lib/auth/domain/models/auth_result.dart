import 'package:equatable/equatable.dart';
import 'package:authentication/auth/domain/models/user.dart';

class AuthResult extends Equatable {
  final User user;
  final String token;

  const AuthResult({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}
 