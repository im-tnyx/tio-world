/// Canonical domain-safe hierarchy for HTTP transport exceptions.
/// Prevents raw HTTP client exceptions (e.g. DioException, SocketException)
/// from leaking into presentation or feature domains.
sealed class TransportException implements Exception {
  const TransportException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => '$runtimeType(statusCode: $statusCode, message: $message)';
}

/// 401 Unauthorized / missing or expired token
class UnauthenticatedException extends TransportException {
  const UnauthenticatedException({
    String message = 'Unauthorized or expired session.',
    int? statusCode = 401,
    Object? cause,
  }) : super(message, statusCode: statusCode, cause: cause);
}

/// 403 Forbidden / deleted or disabled account
class ForbiddenException extends TransportException {
  const ForbiddenException({
    String message = 'Access forbidden or account disabled.',
    int? statusCode = 403,
    Object? cause,
  }) : super(message, statusCode: statusCode, cause: cause);
}

/// 400 / 422 Bad Request / Schema validation rejected
class ValidationException extends TransportException {
  const ValidationException({
    String message = 'Validation rejected by server.',
    int? statusCode = 400,
    this.errors,
    Object? cause,
  }) : super(message, statusCode: statusCode, cause: cause);

  final Map<String, dynamic>? errors;
}

/// 404 Not Found
class NotFoundException extends TransportException {
  const NotFoundException({
    String message = 'Resource not found.',
    int? statusCode = 404,
    Object? cause,
  }) : super(message, statusCode: statusCode, cause: cause);
}

/// 409 Conflict
class ConflictException extends TransportException {
  const ConflictException({
    String message = 'Resource state conflict.',
    int? statusCode = 409,
    Object? cause,
  }) : super(message, statusCode: statusCode, cause: cause);
}

/// 429 Rate Limited
class RateLimitedException extends TransportException {
  const RateLimitedException({
    String message = 'Rate limit exceeded. Please try again later.',
    int? statusCode = 429,
    Object? cause,
  }) : super(message, statusCode: statusCode, cause: cause);
}

/// 5xx Server Error
class ServerException extends TransportException {
  const ServerException({
    String message = 'Server failure encountered.',
    int? statusCode = 500,
    Object? cause,
  }) : super(message, statusCode: statusCode, cause: cause);
}

/// Network unreachable / DNS failure / offline
class NetworkUnavailableException extends TransportException {
  const NetworkUnavailableException({
    String message = 'Network is unavailable or offline.',
    Object? cause,
  }) : super(message, statusCode: null, cause: cause);
}

/// Request timed out
class TimeoutTransportException extends TransportException {
  const TimeoutTransportException({
    String message = 'Request timed out.',
    Object? cause,
  }) : super(message, statusCode: null, cause: cause);
}

/// Unknown / unexpected transport exception
class UnknownTransportException extends TransportException {
  const UnknownTransportException({
    String message = 'An unknown network error occurred.',
    int? statusCode,
    Object? cause,
  }) : super(message, statusCode: statusCode, cause: cause);
}
