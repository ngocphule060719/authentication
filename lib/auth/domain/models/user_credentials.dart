import 'package:equatable/equatable.dart';

class UserCredentials extends Equatable {
  final String email;
  final String userId;

  const UserCredentials({
    required this.email,
    required this.userId,
  });

  @override
  List<Object?> get props => [email, userId];

  @override
  String toString() => 'UserCredentials(email: $email, userId: $userId)';
}
