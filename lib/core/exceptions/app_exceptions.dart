/// Custom exceptions for the ineTeam app with user-friendly error messages.

/// Base exception for all app exceptions.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Exception for authentication-related errors.
class AuthServiceException extends AppException {
  const AuthServiceException(super.message);
}

/// Exception for match-related errors (creation, joining, leaving).
class MatchServiceException extends AppException {
  const MatchServiceException(super.message);
}

/// Exception for validation errors (invalid input, constraints violated).
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Exception for network/connectivity errors.
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Exception for timeout errors.
class TimeoutException extends AppException {
  const TimeoutException(super.message);
}
