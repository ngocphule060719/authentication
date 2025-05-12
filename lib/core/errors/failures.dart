abstract class Failure {
  final String message;
  final String? code;

  Failure(this.message, [this.code]);
}

class AuthenticationFailure extends Failure {
  AuthenticationFailure(String message, [String? code]) : super(message, code);
}

class StorageFailure extends Failure {
  StorageFailure(String message, [String? code]) : super(message, code);
}

class NetworkFailure extends Failure {
  NetworkFailure(String message, [String? code]) : super(message, code);
}
