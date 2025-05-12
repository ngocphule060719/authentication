class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Invalid credentials');
}

class EmailAlreadyExistsException extends AuthException {
  const EmailAlreadyExistsException() : super('Email already exists');
}

class NetworkException extends AuthException {
  const NetworkException() : super('Network connection failed');
}

class UnauthorizedException extends AuthException {
  const UnauthorizedException() : super('Unauthorized');
}

class InvalidEmailException extends AuthException {
  const InvalidEmailException() : super('Invalid email format');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException()
      : super(
            'Password must be at least 8 characters with numbers and letters');
}

class InvalidNameException extends AuthException {
  const InvalidNameException()
      : super('Name must be at least 2 characters and contain only letters');
}

class ServerException extends AuthException {
  const ServerException() : super('Server error occurred');
}

class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
